-- DUA OPTICS cloud database
-- Run this entire file in Supabase SQL Editor.

create table if not exists public.dua_customer_records (
  id text primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  customer_name text not null default '',
  phone text not null default '',
  email text not null default '',
  dob date,
  address text not null default '',
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.dua_customer_records enable row level security;

-- Do not allow public/anon users to read or write customer records.
revoke all on table public.dua_customer_records from anon;
grant select, insert, update, delete on table public.dua_customer_records to authenticated;

drop policy if exists "DUA owners can read their records" on public.dua_customer_records;
drop policy if exists "DUA owners can insert their records" on public.dua_customer_records;
drop policy if exists "DUA owners can update their records" on public.dua_customer_records;
drop policy if exists "DUA owners can delete their records" on public.dua_customer_records;

create policy "DUA owners can read their records"
on public.dua_customer_records
for select to authenticated
using ((select auth.uid()) = owner_id);

create policy "DUA owners can insert their records"
on public.dua_customer_records
for insert to authenticated
with check ((select auth.uid()) = owner_id);

create policy "DUA owners can update their records"
on public.dua_customer_records
for update to authenticated
using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);

create policy "DUA owners can delete their records"
on public.dua_customer_records
for delete to authenticated
using ((select auth.uid()) = owner_id);

create index if not exists dua_customer_records_owner_id_idx
on public.dua_customer_records(owner_id);
