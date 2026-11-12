create schema if not exists private;
create or replace function private.is_active_support_admin()
returns boolean language sql security definer set search_path = '' as $$
  select exists (select 1 from dns_support.support_agents a where a.user_id = (select auth.uid()) and a.active = true and a.role = 'admin');
$$;
revoke all on function private.is_active_support_admin() from public, anon;
grant execute on function private.is_active_support_admin() to authenticated;
drop policy if exists support_agents_admin_list on dns_support.support_agents;
create policy support_agents_admin_list on dns_support.support_agents for select to authenticated using (private.is_active_support_admin());
drop function if exists dns_support.is_active_support_admin();
alter function dns_support.set_ticket_ref() set search_path = '';
alter function dns_support.touch_conversation() set search_path = '';
drop policy if exists exchange_automation_events_deny_clients on public.exchange_automation_events;
create policy exchange_automation_events_deny_clients on public.exchange_automation_events for all to anon, authenticated using (false) with check (false);
