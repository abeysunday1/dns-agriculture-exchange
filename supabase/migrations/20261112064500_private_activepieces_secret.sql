create table if not exists private.exchange_hook_secrets (
  id boolean primary key default true check (id = true),
  secret text not null,
  created_at timestamptz not null default now()
);
revoke all on table private.exchange_hook_secrets from public, anon, authenticated, service_role;
create or replace function public.get_exchange_hook_secret()
returns text language sql security definer set search_path = '' as $$
  select secret from private.exchange_hook_secrets where id = true;
$$;
revoke all on function public.get_exchange_hook_secret() from public, anon, authenticated;
grant execute on function public.get_exchange_hook_secret() to service_role;
-- Provision the secret out-of-band in the private table. Never commit the secret value to source control.
