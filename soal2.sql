-- Soal 2 — Otomasi perubahan persediaan dengan PostgreSQL trigger.
-- Tabel dibuat sesuai struktur yang diberikan dalam soal.

CREATE TABLE IF NOT EXISTS public.inventory_items (
    item_id VARCHAR(10) PRIMARY KEY,
    item_name VARCHAR(100),
    stock_qty INT NOT NULL DEFAULT 0,
    unit_cost NUMERIC(15, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.inventory_transactions (
    trx_id SERIAL PRIMARY KEY,
    item_id VARCHAR(10) REFERENCES public.inventory_items(item_id),
    trx_type VARCHAR(10) CHECK (trx_type IN ('PURCHASE', 'SALE', 'ADJUSTMENT')),
    qty INT NOT NULL,
    trx_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trigger function memeriksa transaksi, mengunci baris barang, lalu mengubah stok.
-- ADJUSTMENT menggunakan kuantitas bertanda: positif menambah stok,
-- negatif mengurangi stok; nol tidak diperbolehkan.
CREATE OR REPLACE FUNCTION public.trg_update_stock_and_journal()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
DECLARE
    current_stock INT;
    resulting_stock INT;
BEGIN
    IF NEW.item_id IS NULL THEN
        RAISE EXCEPTION 'item_id wajib diisi';
    END IF;

    IF NEW.trx_type IS NULL THEN
        RAISE EXCEPTION 'trx_type wajib diisi';
    END IF;

    IF NEW.qty IS NULL THEN
        RAISE EXCEPTION 'qty wajib diisi';
    END IF;

    IF NEW.trx_type IN ('PURCHASE', 'SALE') AND NEW.qty <= 0 THEN
        RAISE EXCEPTION 'qty untuk PURCHASE dan SALE harus lebih besar dari nol';
    END IF;

    IF NEW.trx_type = 'ADJUSTMENT' AND NEW.qty = 0 THEN
        RAISE EXCEPTION 'qty ADJUSTMENT tidak boleh nol';
    END IF;

    -- Mengunci baris sampai transaksi selesai agar perubahan bersamaan
    -- pada barang yang sama tidak membaca stok lama yang sama.
    SELECT stock_qty
      INTO current_stock
      FROM public.inventory_items
     WHERE item_id = NEW.item_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Barang dengan item_id % tidak ditemukan', NEW.item_id;
    END IF;

    CASE NEW.trx_type
        WHEN 'PURCHASE' THEN
            resulting_stock := current_stock + NEW.qty;
        WHEN 'SALE' THEN
            resulting_stock := current_stock - NEW.qty;
        WHEN 'ADJUSTMENT' THEN
            resulting_stock := current_stock + NEW.qty;
        ELSE
            -- Melindungi function bila nilai trx_type tidak valid.
            RAISE EXCEPTION 'trx_type tidak valid: %', NEW.trx_type;
    END CASE;

    IF resulting_stock < 0 THEN
        IF NEW.trx_type = 'SALE' THEN
            RAISE EXCEPTION
                'Stok tidak mencukupi untuk SALE item_id % (stok %, qty %)',
                NEW.item_id, current_stock, NEW.qty;
        ELSE
            RAISE EXCEPTION
                'Stok akhir tidak boleh negatif untuk ADJUSTMENT item_id % (stok %, qty %)',
                NEW.item_id, current_stock, NEW.qty;
        END IF;
    END IF;

    UPDATE public.inventory_items
       SET stock_qty = resulting_stock
     WHERE item_id = NEW.item_id;

    RETURN NEW;
END;
$function$;

-- BEFORE INSERT menjaga agar stok diperiksa dan diperbarui secara atomik
-- dengan pencatatan transaksi; kegagalan insert membatalkan perubahan stok.
DROP TRIGGER IF EXISTS trg_inventory_transactions_update_stock
    ON public.inventory_transactions;

CREATE TRIGGER trg_inventory_transactions_update_stock
BEFORE INSERT ON public.inventory_transactions
FOR EACH ROW
EXECUTE FUNCTION public.trg_update_stock_and_journal();

-- ============================================================
-- PENGUJIAN MANUAL
-- Jalankan setiap blok secara terpisah. Setiap blok diakhiri
-- ROLLBACK agar data uji dan perubahan stok tidak tersimpan.
-- Pilih item_id uji yang belum digunakan di database.
-- ============================================================

-- Uji 1: PURCHASE menambah stok dari 0 menjadi 10.
BEGIN;
INSERT INTO public.inventory_items (item_id, item_name, stock_qty, unit_cost)
VALUES ('T2PUR001', 'Uji purchase', 0, 1000.00);
INSERT INTO public.inventory_transactions (item_id, trx_type, qty)
VALUES ('T2PUR001', 'PURCHASE', 10);
SELECT item_id, stock_qty FROM public.inventory_items WHERE item_id = 'T2PUR001';
-- Hasil yang diharapkan: stock_qty = 10.
ROLLBACK;

-- Uji 2: SALE yang berhasil mengurangi stok dari 10 menjadi 6.
BEGIN;
INSERT INTO public.inventory_items (item_id, item_name, stock_qty, unit_cost)
VALUES ('T2SAL001', 'Uji sale berhasil', 10, 1000.00);
INSERT INTO public.inventory_transactions (item_id, trx_type, qty)
VALUES ('T2SAL001', 'SALE', 4);
SELECT item_id, stock_qty FROM public.inventory_items WHERE item_id = 'T2SAL001';
-- Hasil yang diharapkan: stock_qty = 6.
ROLLBACK;

-- Uji 3: SALE melebihi stok harus ditolak; DO menangkap hanya error
-- stok tidak mencukupi agar blok uji dapat berakhir dan di-ROLLBACK.
BEGIN;
INSERT INTO public.inventory_items (item_id, item_name, stock_qty, unit_cost)
VALUES ('T2OVR001', 'Uji sale melebihi stok', 5, 1000.00);
DO $test$
DECLARE
    sale_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO public.inventory_transactions (item_id, trx_type, qty)
        VALUES ('T2OVR001', 'SALE', 6);
    EXCEPTION
        WHEN SQLSTATE 'P0001' THEN
            IF SQLERRM =
               'Stok tidak mencukupi untuk SALE item_id T2OVR001 (stok 5, qty 6)' THEN
                sale_rejected := TRUE;
            ELSE
                RAISE;
            END IF;
    END;

    IF NOT sale_rejected THEN
        RAISE EXCEPTION 'Uji gagal: SALE melebihi stok tidak ditolak';
    END IF;
END;
$test$;
SELECT item_id, stock_qty FROM public.inventory_items WHERE item_id = 'T2OVR001';
-- Hasil yang diharapkan: error SALE ditangani oleh blok uji dan stock_qty = 5.
ROLLBACK;

-- Uji 4: ADJUSTMENT negatif mengurangi stok dari 10 menjadi 7.
BEGIN;
INSERT INTO public.inventory_items (item_id, item_name, stock_qty, unit_cost)
VALUES ('T2ADJ001', 'Uji adjustment', 10, 1000.00);
INSERT INTO public.inventory_transactions (item_id, trx_type, qty)
VALUES ('T2ADJ001', 'ADJUSTMENT', -3);
SELECT item_id, stock_qty FROM public.inventory_items WHERE item_id = 'T2ADJ001';
-- Hasil yang diharapkan: stock_qty = 7.
ROLLBACK;
