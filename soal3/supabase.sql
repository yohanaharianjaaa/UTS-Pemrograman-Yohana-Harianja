-- Soal 3: schema, access policies, audit trail, and transactional RPCs.
-- Run once in the Supabase SQL Editor. This schema is independent of Soal 1.

create extension if not exists pgcrypto with schema extensions;

create sequence if not exists public.cash_voucher_number_seq;

create table if not exists public.chart_of_accounts (
    account_id uuid primary key default gen_random_uuid(),
    account_code text not null unique,
    account_name text not null,
    is_active boolean not null default true
);

create table if not exists public.cash_vouchers (
    voucher_id uuid primary key default gen_random_uuid(),
    voucher_number text not null unique default (
        'CDV-' || to_char(current_date, 'YYMM') || '-' ||
        lpad(nextval('public.cash_voucher_number_seq')::text, 5, '0')
    ),
    transaction_date date,
    payee text,
    description text,
    status text not null default 'DRAFT'
        check (status in ('DRAFT', 'POSTED')),
    created_by uuid not null references auth.users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    posted_at timestamptz,
    hash_checksum text,
    reversal_of uuid unique references public.cash_vouchers(voucher_id),
    constraint cash_vouchers_posted_checksum check (
        (status = 'DRAFT' and posted_at is null and hash_checksum is null)
        or
        (status = 'POSTED' and posted_at is not null and hash_checksum is not null)
    )
);

create table if not exists public.cash_voucher_lines (
    line_id bigint generated always as identity primary key,
    voucher_id uuid not null references public.cash_vouchers(voucher_id) on delete restrict,
    line_number integer not null check (line_number > 0),
    account_id uuid references public.chart_of_accounts(account_id),
    line_description text,
    debit numeric(18, 2) not null default 0 check (debit >= 0),
    credit numeric(18, 2) not null default 0 check (credit >= 0),
    constraint cash_voucher_lines_unique_number unique (voucher_id, line_number),
    constraint cash_voucher_lines_one_side check (debit = 0 or credit = 0)
);

create table if not exists public.audit_logs (
    audit_id bigint generated always as identity primary key,
    voucher_id uuid not null references public.cash_vouchers(voucher_id),
    actor_id uuid not null references auth.users(id),
    action text not null check (action in ('DRAFT_SAVED', 'POSTED', 'REVERSED')),
    occurred_at timestamptz not null default now(),
    hash_checksum text,
    details jsonb not null default '{}'::jsonb
);

insert into public.chart_of_accounts (account_code, account_name) values
    ('110-10', 'Kas Kecil (Petty Cash)'),
    ('110-20', 'Bank BCA'),
    ('110-21', 'Bank Mandiri'),
    ('510-10', 'Beban Listrik'),
    ('510-11', 'Beban Air'),
    ('510-12', 'Beban Telepon & Internet'),
    ('510-20', 'Beban Sewa Kantor'),
    ('510-30', 'Beban Perlengkapan (Supplies)'),
    ('210-10', 'Hutang Usaha (Accounts Payable)')
on conflict (account_code) do nothing;

create or replace function public.guard_posted_voucher()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
    if tg_op = 'DELETE' then
        if old.status = 'POSTED' then
            raise exception 'Voucher POSTED tidak dapat dihapus; gunakan jurnal pembalik';
        end if;
        return old;
    end if;

    if old.status = 'POSTED' then
        raise exception 'Voucher POSTED tidak dapat diubah; gunakan jurnal pembalik';
    end if;
    return new;
end;
$$;

create or replace function public.guard_posted_voucher_line()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
    target_voucher_id uuid;
    target_status text;
begin
    if tg_op = 'DELETE' or tg_op = 'UPDATE' then
        select status into target_status
          from public.cash_vouchers where voucher_id = old.voucher_id;
        if target_status = 'POSTED' then
            raise exception 'Rincian voucher POSTED tidak dapat diubah atau dihapus';
        end if;
    end if;

    if tg_op = 'INSERT' or tg_op = 'UPDATE' then
        target_voucher_id := new.voucher_id;
        select status into target_status
          from public.cash_vouchers where voucher_id = target_voucher_id;
        if target_status = 'POSTED' then
            raise exception 'Rincian voucher POSTED tidak dapat diubah atau ditambah';
        end if;
    end if;

    if tg_op = 'DELETE' then return old; end if;
    return new;
end;
$$;

create or replace function public.guard_audit_log()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
    raise exception 'Audit log bersifat immutable';
end;
$$;

drop trigger if exists cash_vouchers_immutable on public.cash_vouchers;
create trigger cash_vouchers_immutable
before update or delete on public.cash_vouchers
for each row execute function public.guard_posted_voucher();

drop trigger if exists cash_voucher_lines_immutable on public.cash_voucher_lines;
create trigger cash_voucher_lines_immutable
before insert or update or delete on public.cash_voucher_lines
for each row execute function public.guard_posted_voucher_line();

drop trigger if exists audit_logs_immutable on public.audit_logs;
create trigger audit_logs_immutable
before update or delete on public.audit_logs
for each row execute function public.guard_audit_log();

alter table public.chart_of_accounts enable row level security;
alter table public.cash_vouchers enable row level security;
alter table public.cash_voucher_lines enable row level security;
alter table public.audit_logs enable row level security;

drop policy if exists "Authenticated users read active accounts" on public.chart_of_accounts;
create policy "Authenticated users read active accounts"
on public.chart_of_accounts for select to authenticated
using (is_active);

drop policy if exists "Users read their vouchers" on public.cash_vouchers;
create policy "Users read their vouchers"
on public.cash_vouchers for select to authenticated
using (created_by = (select auth.uid()));

drop policy if exists "Users read lines of their vouchers" on public.cash_voucher_lines;
create policy "Users read lines of their vouchers"
on public.cash_voucher_lines for select to authenticated
using (exists (
    select 1 from public.cash_vouchers v
    where v.voucher_id = cash_voucher_lines.voucher_id
      and v.created_by = (select auth.uid())
));

drop policy if exists "Users read their audit events" on public.audit_logs;
create policy "Users read their audit events"
on public.audit_logs for select to authenticated
using (actor_id = (select auth.uid()));

revoke all on public.chart_of_accounts, public.cash_vouchers,
    public.cash_voucher_lines, public.audit_logs from anon, authenticated;
grant select on public.chart_of_accounts, public.cash_vouchers,
    public.cash_voucher_lines, public.audit_logs to authenticated;

create or replace function public.voucher_checksum(p_voucher_id uuid)
returns text
language sql
stable
security definer
set search_path = public, extensions, pg_temp
as $$
    select encode(digest(
        jsonb_build_object(
            'voucher_id', v.voucher_id,
            'voucher_number', v.voucher_number,
            'transaction_date', v.transaction_date,
            'payee', v.payee,
            'description', v.description,
            'created_by', v.created_by,
            'created_at', v.created_at,
            'lines', coalesce((
                select jsonb_agg(jsonb_build_object(
                    'line_number', l.line_number,
                    'account_code', a.account_code,
                    'line_description', l.line_description,
                    'debit', l.debit,
                    'credit', l.credit
                ) order by l.line_number)
                from public.cash_voucher_lines l
                left join public.chart_of_accounts a on a.account_id = l.account_id
                where l.voucher_id = v.voucher_id
            ), '[]'::jsonb)
        )::text,
        'sha256'
    ), 'hex')
    from public.cash_vouchers v
    where v.voucher_id = p_voucher_id;
$$;

create or replace function public.check_cash_voucher_checksum(p_voucher_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
    stored_checksum text;
begin
    select hash_checksum into stored_checksum
      from public.cash_vouchers
     where voucher_id = p_voucher_id and created_by = auth.uid();
    if not found then
        raise exception 'Voucher tidak ditemukan atau bukan milik pengguna ini';
    end if;
    if stored_checksum is null then
        return false;
    end if;
    return stored_checksum = public.voucher_checksum(p_voucher_id);
end;
$$;

create or replace function public.save_cash_voucher(
    p_voucher_id uuid,
    p_transaction_date date,
    p_payee text,
    p_description text,
    p_lines jsonb,
    p_post boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
    current_user_id uuid := auth.uid();
    target_id uuid;
    target_number text;
    line_count integer;
    debit_total numeric(18, 2);
    credit_total numeric(18, 2);
    invalid_line boolean;
    checksum text;
    new_status text := case when p_post then 'POSTED' else 'DRAFT' end;
begin
    if current_user_id is null then
        raise exception 'Autentikasi diperlukan';
    end if;
    if p_lines is null or jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines) > 200 then
        raise exception 'Rincian jurnal harus berupa array dengan maksimal 200 baris';
    end if;

    if exists (
        select 1
        from jsonb_to_recordset(p_lines) as x(account_code text, debit numeric, credit numeric)
        left join public.chart_of_accounts a
          on a.account_code = nullif(trim(x.account_code), '') and a.is_active
        where nullif(trim(x.account_code), '') is not null and a.account_id is null
    ) then
        raise exception 'Kode akun tidak ditemukan atau tidak aktif';
    end if;

    if p_post then
        if p_transaction_date is null or nullif(trim(p_payee), '') is null
            or nullif(trim(p_description), '') is null then
            raise exception 'Tanggal, penerima, dan deskripsi wajib diisi untuk posting';
        end if;

        select count(*),
               coalesce(sum(coalesce(x.debit, 0)), 0),
               coalesce(sum(coalesce(x.credit, 0)), 0),
               coalesce(bool_or(
                   nullif(trim(x.account_code), '') is null
                   or (coalesce(x.debit, 0) <= 0 and coalesce(x.credit, 0) <= 0)
                   or (coalesce(x.debit, 0) > 0 and coalesce(x.credit, 0) > 0)
                   or coalesce(x.debit, 0) < 0
                   or coalesce(x.credit, 0) < 0
               ), true)
          into line_count, debit_total, credit_total, invalid_line
          from jsonb_to_recordset(p_lines) as x(
              account_code text, line_description text, debit numeric, credit numeric
          );

        if line_count < 2 or invalid_line then
            raise exception 'Posting memerlukan minimal dua baris valid; tiap baris harus memiliki akun dan hanya satu nominal positif';
        end if;
        if debit_total <= 0 or debit_total <> credit_total then
            raise exception 'Jurnal tidak seimbang: debit % dan kredit %', debit_total, credit_total;
        end if;
    end if;

    if p_voucher_id is null then
        insert into public.cash_vouchers (
            transaction_date, payee, description, created_by
        ) values (
            p_transaction_date, nullif(trim(p_payee), ''),
            nullif(trim(p_description), ''), current_user_id
        )
        returning voucher_id, voucher_number into target_id, target_number;
    else
        select voucher_id, voucher_number into target_id, target_number
          from public.cash_vouchers
         where voucher_id = p_voucher_id and created_by = current_user_id
         for update;
        if not found then
            raise exception 'Voucher tidak ditemukan atau bukan milik pengguna ini';
        end if;
        if (select status from public.cash_vouchers where voucher_id = target_id) <> 'DRAFT' then
            raise exception 'Voucher POSTED tidak dapat diedit; gunakan jurnal pembalik';
        end if;

        update public.cash_vouchers
           set transaction_date = p_transaction_date,
               payee = nullif(trim(p_payee), ''),
               description = nullif(trim(p_description), ''),
               updated_at = now()
         where voucher_id = target_id;
        delete from public.cash_voucher_lines where voucher_id = target_id;
    end if;

    insert into public.cash_voucher_lines (
        voucher_id, line_number, account_id, line_description, debit, credit
    )
    select target_id, x.ordinality::integer, a.account_id,
           nullif(trim(x.line_description), ''),
           coalesce(x.debit, 0), coalesce(x.credit, 0)
      from jsonb_to_recordset(p_lines) with ordinality as x(
          account_code text, line_description text, debit numeric, credit numeric, ordinality bigint
      )
      left join public.chart_of_accounts a
        on a.account_code = nullif(trim(x.account_code), '') and a.is_active;

    if p_post then
        checksum := public.voucher_checksum(target_id);
        update public.cash_vouchers
           set status = 'POSTED', posted_at = now(), updated_at = now(),
               hash_checksum = checksum
         where voucher_id = target_id;
    end if;

    insert into public.audit_logs (voucher_id, actor_id, action, hash_checksum, details)
    values (
        target_id, current_user_id, case when p_post then 'POSTED' else 'DRAFT_SAVED' end,
        checksum,
        jsonb_build_object('voucher_number', target_number, 'status', new_status)
    );

    return jsonb_build_object(
        'voucher_id', target_id,
        'voucher_number', target_number,
        'status', new_status,
        'hash_checksum', checksum
    );
end;
$$;

create or replace function public.reverse_cash_voucher(p_voucher_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
    current_user_id uuid := auth.uid();
    source public.cash_vouchers%rowtype;
    reversal_id uuid;
    reversal_number text;
    checksum text;
begin
    if current_user_id is null then raise exception 'Autentikasi diperlukan'; end if;
    select * into source
      from public.cash_vouchers
     where voucher_id = p_voucher_id and created_by = current_user_id
     for update;
    if not found or source.status <> 'POSTED' then
        raise exception 'Hanya voucher POSTED milik pengguna ini yang dapat dibalik';
    end if;
    if exists (select 1 from public.cash_vouchers where reversal_of = source.voucher_id) then
        raise exception 'Voucher ini sudah memiliki jurnal pembalik';
    end if;

    insert into public.cash_vouchers (
        transaction_date, payee, description, status, created_by, posted_at, reversal_of
    ) values (
        current_date, source.payee, 'Jurnal pembalik untuk ' || source.voucher_number,
        'DRAFT', current_user_id, null, source.voucher_id
    )
    returning voucher_id, voucher_number into reversal_id, reversal_number;

    insert into public.cash_voucher_lines (
        voucher_id, line_number, account_id, line_description, debit, credit
    )
    select reversal_id, line_number, account_id,
           'Pembalik: ' || coalesce(line_description, ''),
           credit, debit
      from public.cash_voucher_lines
     where voucher_id = source.voucher_id
     order by line_number;

    checksum := public.voucher_checksum(reversal_id);
    update public.cash_vouchers
       set status = 'POSTED', posted_at = now(), updated_at = now(),
           hash_checksum = checksum
     where voucher_id = reversal_id;

    insert into public.audit_logs (voucher_id, actor_id, action, hash_checksum, details)
    values
        (source.voucher_id, current_user_id, 'REVERSED', source.hash_checksum,
         jsonb_build_object('reversal_voucher_id', reversal_id, 'reversal_voucher_number', reversal_number)),
        (reversal_id, current_user_id, 'POSTED', checksum,
         jsonb_build_object('reverses_voucher_id', source.voucher_id, 'status', 'POSTED'));

    return jsonb_build_object(
        'voucher_id', reversal_id,
        'voucher_number', reversal_number,
        'status', 'POSTED',
        'hash_checksum', checksum
    );
end;
$$;

revoke all on function public.voucher_checksum(uuid) from public, anon, authenticated;
revoke all on function public.check_cash_voucher_checksum(uuid) from public, anon, authenticated;
revoke all on function public.save_cash_voucher(uuid, date, text, text, jsonb, boolean) from public, anon, authenticated;
revoke all on function public.reverse_cash_voucher(uuid) from public, anon, authenticated;
grant execute on function public.check_cash_voucher_checksum(uuid) to authenticated;
grant execute on function public.save_cash_voucher(uuid, date, text, text, jsonb, boolean) to authenticated;
grant execute on function public.reverse_cash_voucher(uuid) to authenticated;
