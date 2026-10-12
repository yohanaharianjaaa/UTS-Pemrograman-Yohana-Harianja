-- DDL PostgreSQL untuk skema General Ledger Soal 1.
-- Jalankan pada database PostgreSQL yang dipilih.

CREATE TABLE chart_of_accounts (
    account_id BIGINT GENERATED ALWAYS AS IDENTITY,
    account_code VARCHAR(20) NOT NULL,
    account_name VARCHAR(150) NOT NULL,
    normal_balance_type VARCHAR(6) NOT NULL,
    report_classification VARCHAR(30) NOT NULL,

    CONSTRAINT pk_chart_of_accounts PRIMARY KEY (account_id),
    CONSTRAINT uq_chart_of_accounts_account_code UNIQUE (account_code),
    CONSTRAINT ck_chart_of_accounts_normal_balance
        CHECK (normal_balance_type IN ('DEBIT', 'CREDIT'))
);

CREATE TABLE journal_headers (
    journal_id BIGINT GENERATED ALWAYS AS IDENTITY,
    transaction_date DATE NOT NULL,
    reference_number VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    posting_status VARCHAR(20) NOT NULL,

    CONSTRAINT pk_journal_headers PRIMARY KEY (journal_id)
);

CREATE TABLE journal_lines (
    journal_line_id BIGINT GENERATED ALWAYS AS IDENTITY,
    header_id BIGINT NOT NULL,
    account_id BIGINT NOT NULL,
    debit NUMERIC(18, 2) NOT NULL DEFAULT 0,
    credit NUMERIC(18, 2) NOT NULL DEFAULT 0,

    CONSTRAINT pk_journal_lines PRIMARY KEY (journal_line_id),
    CONSTRAINT fk_journal_lines_header
        FOREIGN KEY (header_id)
        REFERENCES journal_headers (journal_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_journal_lines_account
        FOREIGN KEY (account_id)
        REFERENCES chart_of_accounts (account_id)
        ON DELETE RESTRICT,
    CONSTRAINT ck_journal_lines_debit_nonnegative
        CHECK (debit >= 0),
    CONSTRAINT ck_journal_lines_credit_nonnegative
        CHECK (credit >= 0),
    CONSTRAINT ck_journal_lines_not_both_zero
        CHECK (debit > 0 OR credit > 0)
);

-- CHECK di atas memeriksa nominal pada setiap baris.
-- Keseimbangan total debit dan kredit per jurnal adalah aturan lintas baris
-- dan tidak dijamin oleh CHECK per baris.
