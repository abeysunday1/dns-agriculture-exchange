create table if not exists public.exchange_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  account_type text not null check (account_type in ('buyer','supplier')),
  account_status text not null default 'pending' check (account_status in ('pending','active','suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.exchange_profiles enable row level security;
revoke all on public.exchange_profiles from anon, authenticated;
grant select on public.exchange_profiles to authenticated;
drop policy if exists "Users read own exchange profile" on public.exchange_profiles;
create policy "Users read own exchange profile"
on public.exchange_profiles for select to authenticated
using (user_id = (select auth.uid()));

create or replace function public.handle_new_exchange_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_role text;
begin
  requested_role := coalesce(new.raw_user_meta_data ->> 'account_type', 'buyer');
  if requested_role not in ('buyer','supplier') then requested_role := 'buyer'; end if;
  insert into public.exchange_profiles (user_id, full_name, account_type)
  values (new.id, nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), requested_role)
  on conflict (user_id) do nothing;
  return new;
end;
$$;
revoke all on function public.handle_new_exchange_user() from public, anon, authenticated;
drop trigger if exists on_auth_user_created_exchange_profile on auth.users;
create trigger on_auth_user_created_exchange_profile
after insert on auth.users
for each row execute function public.handle_new_exchange_user();
