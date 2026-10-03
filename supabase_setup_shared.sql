-- DUA OPTICS shared cloud database - NO EMAIL LOGIN
-- 1) In Supabase Dashboard -> Authentication -> Providers, enable Anonymous Sign-Ins.
-- 2) Run this entire file in SQL Editor.
-- 3) The app uses the access code below on every device.
--    Change it before production if you want your own code.

create extension if not exists pgcrypto;

create table if not exists public.dua_workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  access_code_hash text not null
);

create table if not exists public.dua_workspace_members (
  workspace_id uuid not null references public.dua_workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (workspace_id,user_id)
);

create table if not exists public.dua_customer_records_shared (
  id text primary key,
  workspace_id uuid not null references public.dua_workspaces(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- Create the single shared DUA OPTICS workspace.
insert into public.dua_workspaces(name,access_code_hash)
select 'DUA OPTICS', crypt('DUA-OPTICS-4827', gen_salt('bf'))
where not exists (select 1 from public.dua_workspaces);

alter table public.dua_workspaces enable row level security;
alter table public.dua_workspace_members enable row level security;
alter table public.dua_customer_records_shared enable row level security;

revoke all on table public.dua_workspaces from anon,authenticated;
revoke all on table public.dua_workspace_members from anon,authenticated;
grant select,insert,update,delete on table public.dua_customer_records_shared to authenticated;

-- Secure function: the access code is checked on the server. The code itself is never stored in the app database as plain text.
create or replace function public.join_dua_workspace(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare v_workspace uuid;
begin
  select id into v_workspace
  from public.dua_workspaces
  where access_code_hash = crypt(trim(p_code), access_code_hash)
  limit 1;
  if v_workspace is null then raise exception 'Invalid DUA OPTICS access code'; end if;
  insert into public.dua_workspace_members(workspace_id,user_id)
  values(v_workspace,auth.uid()) on conflict do nothing;
  return v_workspace;
end;
$$;

create or replace function public.get_dua_workspace()
returns uuid
language sql
security definer
set search_path = public
as $$
  select workspace_id from public.dua_workspace_members where user_id=auth.uid() limit 1;
$$;

grant execute on function public.join_dua_workspace(text) to authenticated;
grant execute on function public.get_dua_workspace() to authenticated;

drop policy if exists "DUA shared members read" on public.dua_customer_records_shared;
drop policy if exists "DUA shared members insert" on public.dua_customer_records_shared;
drop policy if exists "DUA shared members update" on public.dua_customer_records_shared;
drop policy if exists "DUA shared members delete" on public.dua_customer_records_shared;

create policy "DUA shared members read"
on public.dua_customer_records_shared for select to authenticated
using (exists (select 1 from public.dua_workspace_members m where m.workspace_id=dua_customer_records_shared.workspace_id and m.user_id=auth.uid()));

create policy "DUA shared members insert"
on public.dua_customer_records_shared for insert to authenticated
with check (exists (select 1 from public.dua_workspace_members m where m.workspace_id=dua_customer_records_shared.workspace_id and m.user_id=auth.uid()));

create policy "DUA shared members update"
on public.dua_customer_records_shared for update to authenticated
using (exists (select 1 from public.dua_workspace_members m where m.workspace_id=dua_customer_records_shared.workspace_id and m.user_id=auth.uid()))
with check (exists (select 1 from public.dua_workspace_members m where m.workspace_id=dua_customer_records_shared.workspace_id and m.user_id=auth.uid()));

create policy "DUA shared members delete"
on public.dua_customer_records_shared for delete to authenticated
using (exists (select 1 from public.dua_workspace_members m where m.workspace_id=dua_customer_records_shared.workspace_id and m.user_id=auth.uid()));

create index if not exists dua_customer_records_shared_workspace_idx on public.dua_customer_records_shared(workspace_id);
