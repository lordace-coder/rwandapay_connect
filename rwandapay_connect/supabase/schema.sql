-- RwandaPay Connect - Supabase Schema
-- Run this ENTIRE file in the Supabase SQL Editor:
--   https://supabase.com/dashboard/project/dohwtewodbheczloukyh/sql/new
--
-- Safe to run more than once: it drops and recreates everything.

-- ============================================
-- RESET (so re-running gives a clean demo state)
-- ============================================
drop table if exists public.momo_payouts cascade;
drop table if exists public.transactions cascade;
drop table if exists public.accounts cascade;
drop table if exists public.users cascade;

create extension if not exists "uuid-ossp";

-- ============================================
-- USERS TABLE
-- ============================================
create table public.users (
  id uuid default uuid_generate_v4() primary key,
  full_name text not null,
  email text unique not null,
  password_hash text not null,
  role text not null check (role in ('sender', 'receiver', 'admin')),
  country text not null default '',
  phone text not null default '',
  account_number text unique not null,
  id_type text not null default '',
  id_number text not null default '',
  address text,
  momo_provider text,
  verification_status text not null default 'verified',
  created_at timestamptz default now()
);

-- ============================================
-- ACCOUNTS TABLE
-- ============================================
create table public.accounts (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  currency text not null check (currency in ('USD', 'RWF')),
  balance numeric(15,2) not null default 0,
  updated_at timestamptz default now()
);

-- ============================================
-- TRANSACTIONS TABLE
-- ============================================
create table public.transactions (
  id uuid default uuid_generate_v4() primary key,
  sender_id uuid references public.users(id) not null,
  receiver_id uuid references public.users(id) not null,
  amount_usd numeric(15,2) not null,
  fee_usd numeric(15,2) not null,
  exchange_rate_used numeric(15,4) not null,
  amount_rwf numeric(15,2) not null,
  status text not null default 'sent' check (status in ('sent', 'received', 'sent_to_momo')),
  momo_number_used text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ============================================
-- MOMO PAYOUTS TABLE
-- ============================================
create table public.momo_payouts (
  id uuid default uuid_generate_v4() primary key,
  transaction_id uuid references public.transactions(id) on delete cascade not null,
  momo_number text not null,
  amount_rwf numeric(15,2) not null,
  simulated_status text not null default 'completed',
  processed_at timestamptz default now()
);

-- ============================================
-- INDEXES
-- ============================================
create index idx_accounts_user_id on public.accounts(user_id);
create index idx_transactions_sender_id on public.transactions(sender_id);
create index idx_transactions_receiver_id on public.transactions(receiver_id);
create index idx_momo_payouts_transaction_id on public.momo_payouts(transaction_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- Demo only: the anon key may read and write everything.
-- This is intentional for a simulated classroom demo. Do NOT use
-- these policies for anything holding real money or real personal data.
-- ============================================
alter table public.users enable row level security;
alter table public.accounts enable row level security;
alter table public.transactions enable row level security;
alter table public.momo_payouts enable row level security;

create policy "Allow all for demo" on public.users for all using (true) with check (true);
create policy "Allow all for demo" on public.accounts for all using (true) with check (true);
create policy "Allow all for demo" on public.transactions for all using (true) with check (true);
create policy "Allow all for demo" on public.momo_payouts for all using (true) with check (true);

-- ============================================
-- ATOMIC MONEY TRANSFER
-- Debits the sender, credits the receiver, and writes the transaction
-- row in ONE database transaction. If any step fails, none of it applies,
-- so balances can never drift out of sync with the transaction log.
-- ============================================
create or replace function public.send_money(
  p_sender_id uuid,
  p_receiver_id uuid,
  p_amount_usd numeric,
  p_fee_usd numeric,
  p_exchange_rate numeric,
  p_amount_rwf numeric,
  p_momo_number text
)
returns public.transactions
language plpgsql
as $$
declare
  v_sender_balance numeric;
  v_txn public.transactions;
begin
  -- Lock the sender's account row so two sends can't both pass the check
  select balance into v_sender_balance
  from public.accounts
  where user_id = p_sender_id
  for update;

  if v_sender_balance is null then
    raise exception 'Sender account not found';
  end if;

  if v_sender_balance < (p_amount_usd + p_fee_usd) then
    raise exception 'Insufficient balance';
  end if;

  update public.accounts
  set balance = balance - (p_amount_usd + p_fee_usd),
      updated_at = now()
  where user_id = p_sender_id;

  update public.accounts
  set balance = balance + p_amount_rwf,
      updated_at = now()
  where user_id = p_receiver_id;

  insert into public.transactions (
    sender_id, receiver_id, amount_usd, fee_usd,
    exchange_rate_used, amount_rwf, status, momo_number_used
  )
  values (
    p_sender_id, p_receiver_id, p_amount_usd, p_fee_usd,
    p_exchange_rate, p_amount_rwf, 'received', p_momo_number
  )
  returning * into v_txn;

  return v_txn;
end;
$$;

-- ============================================
-- ATOMIC MOMO CASH-OUT
-- Marks the transaction sent_to_momo, records the payout, and debits
-- the receiver's in-app balance together.
-- ============================================
create or replace function public.cash_out_to_momo(
  p_transaction_id uuid
)
returns public.transactions
language plpgsql
as $$
declare
  v_txn public.transactions;
begin
  select * into v_txn
  from public.transactions
  where id = p_transaction_id
  for update;

  if v_txn is null then
    raise exception 'Transaction not found';
  end if;

  if v_txn.status = 'sent_to_momo' then
    raise exception 'Already sent to MoMo';
  end if;

  update public.transactions
  set status = 'sent_to_momo',
      updated_at = now()
  where id = p_transaction_id
  returning * into v_txn;

  insert into public.momo_payouts (transaction_id, momo_number, amount_rwf)
  values (p_transaction_id, coalesce(v_txn.momo_number_used, ''), v_txn.amount_rwf);

  update public.accounts
  set balance = greatest(balance - v_txn.amount_rwf, 0),
      updated_at = now()
  where user_id = v_txn.receiver_id;

  return v_txn;
end;
$$;

-- ============================================
-- SEED DATA
-- Passwords are SHA-256 hashes of the values in PHASES.md.
--   Sender@2026     -> 69eee62f...
--   Receiver1@2026  -> ef0eddc6...
--   Receiver2@2026  -> 238d600f...
--   Admin@2026      -> a36aef5a...
-- ============================================

-- Sender: James Whitmore / Sender@2026
insert into public.users (id, full_name, email, password_hash, role, country, phone, account_number, id_type, id_number, address)
values (
  'a1b2c3d4-0001-4000-8000-000000000001',
  'James Whitmore',
  'james.whitmore@demo-rwandapay.com',
  '69eee62fd440daf76fff63f621a3fbd5db81c028d586e4948d7aea3bc9a382ab',
  'sender',
  'United States',
  '+1 (404) 555-0142',
  'RWC-US-0001',
  'US Driver''s License',
  'GA-04559213',
  '4821 Maple Grove Ave, Atlanta, GA 30301, USA'
);

insert into public.accounts (user_id, currency, balance)
values ('a1b2c3d4-0001-4000-8000-000000000001', 'USD', 500.00);

-- Receiver 1: Uwase Aline / Receiver1@2026
insert into public.users (id, full_name, email, password_hash, role, country, phone, account_number, id_type, id_number, address, momo_provider)
values (
  'a1b2c3d4-0002-4000-8000-000000000002',
  'Uwase Aline',
  'uwase.aline@demo-rwandapay.com',
  'ef0eddc6ae617d6e839b32570c6f834652ad8f5fd5183da8debc404077650556',
  'receiver',
  'Rwanda',
  '+250 788 123 456',
  'RWC-RW-0001',
  'Rwandan National ID',
  '1 1990 8 0123456 0 12',
  'KG 231 St, Kimironko, Gasabo District, Kigali',
  'MTN MoMo'
);

insert into public.accounts (user_id, currency, balance)
values ('a1b2c3d4-0002-4000-8000-000000000002', 'RWF', 0);

-- Receiver 2: Niyonzima Eric / Receiver2@2026
insert into public.users (id, full_name, email, password_hash, role, country, phone, account_number, id_type, id_number, address, momo_provider)
values (
  'a1b2c3d4-0003-4000-8000-000000000003',
  'Niyonzima Eric',
  'niyonzima.eric@demo-rwandapay.com',
  '238d600fed94daaed3b0848ff907ac94b0516e89a819f396ad275c29083a171b',
  'receiver',
  'Rwanda',
  '+250 788 987 654',
  'RWC-RW-0002',
  'Rwandan National ID',
  '1 1993 7 0654321 0 27',
  'KG 15 Ave, Remera, Gasabo District, Kigali',
  'MTN MoMo'
);

insert into public.accounts (user_id, currency, balance)
values ('a1b2c3d4-0003-4000-8000-000000000003', 'RWF', 0);

-- Admin: Donald Ehizode / Admin@2026
insert into public.users (id, full_name, email, password_hash, role, country, phone, account_number, id_type, id_number)
values (
  'a1b2c3d4-0004-4000-8000-000000000004',
  'Donald Ehizode',
  'admin@demo-rwandapay.com',
  'a36aef5a11c4073fbe60314fc9df530a9d5f986533594d1f5190742ff9e0e408',
  'admin',
  'Rwanda',
  '',
  'RWC-ADM-0001',
  '',
  ''
);
