create or replace function dns_support.is_active_support_admin()
returns boolean language sql security definer set search_path = '' as $$
  select exists (select 1 from dns_support.support_agents a where a.user_id = (select auth.uid()) and a.active = true and a.role = 'admin');
$$;
revoke all on function dns_support.is_active_support_admin() from public, anon;
grant execute on function dns_support.is_active_support_admin() to authenticated;
drop policy if exists support_agents_admin_list on dns_support.support_agents;
create policy support_agents_admin_list on dns_support.support_agents for select to authenticated using (dns_support.is_active_support_admin());
