-- Immediate server-side account removal plus request audit retention.
create or replace function private.has_live_auth_session()
returns boolean language plpgsql stable security definer set search_path='' as $$
declare v_session_id uuid;
begin
 if auth.uid() is null then return false; end if;
 v_session_id := nullif(auth.jwt()->>'session_id','')::uuid;
 if v_session_id is null then return false; end if;
 return exists(select 1 from auth.sessions s where s.id=v_session_id and s.user_id=auth.uid());
end; $$;
revoke all on function private.has_live_auth_session() from public,anon;
grant execute on function private.has_live_auth_session() to authenticated;

create or replace function private.is_active_support_admin()
returns boolean language sql stable security definer set search_path='' as $$
 select private.has_live_auth_session() and exists(
  select 1 from dns_support.support_agents a
  where a.user_id=(select auth.uid()) and a.active=true and a.role='admin'
 );
$$;
revoke all on function private.is_active_support_admin() from public,anon;
grant execute on function private.is_active_support_admin() to authenticated;

drop policy if exists "Users read active own exchange profile" on public.exchange_profiles;
drop policy if exists exchange_profiles_update_own on public.exchange_profiles;
create policy "Users read active own exchange profile" on public.exchange_profiles for select to authenticated
using(user_id=(select auth.uid()) and deleted_at is null and private.has_live_auth_session());
create policy exchange_profiles_update_own on public.exchange_profiles for update to authenticated
using(user_id=(select auth.uid()) and deleted_at is null and account_status in ('pending','active') and private.has_live_auth_session())
with check(user_id=(select auth.uid()) and deleted_at is null and account_status in ('pending','active') and private.has_live_auth_session());

drop policy if exists exchange_submissions_select_own on public.exchange_submissions;
drop policy if exists exchange_submissions_insert_own on public.exchange_submissions;
create policy exchange_submissions_select_own on public.exchange_submissions for select to authenticated
using(user_id=(select auth.uid()) and private.has_live_auth_session() and exists(select 1 from public.exchange_profiles p where p.user_id=(select auth.uid()) and p.deleted_at is null));
create policy exchange_submissions_insert_own on public.exchange_submissions for insert to authenticated
with check(user_id=(select auth.uid()) and private.has_live_auth_session() and exists(select 1 from public.exchange_profiles p where p.user_id=(select auth.uid()) and p.account_type=submission_type and p.account_status in ('pending','active') and p.deleted_at is null));

drop policy if exists account_deletion_requests_read_own on public.account_deletion_requests;
drop policy if exists account_deletion_requests_insert_own on public.account_deletion_requests;
create policy account_deletion_requests_read_own on public.account_deletion_requests for select to authenticated
using(user_id=(select auth.uid()) and private.has_live_auth_session());
create policy account_deletion_requests_insert_own on public.account_deletion_requests for insert to authenticated
with check(user_id=(select auth.uid()) and status='pending' and private.has_live_auth_session() and exists(
 select 1 from public.exchange_profiles p where p.user_id=(select auth.uid()) and p.deleted_at is null and p.account_status in ('pending','active')
));

alter table public.account_deletion_requests alter column user_id drop not null;
alter table public.account_deletion_requests drop constraint if exists account_deletion_requests_user_id_fkey;
alter table public.account_deletion_requests add constraint account_deletion_requests_user_id_fkey foreign key(user_id) references auth.users(id) on delete set null;

drop policy if exists support_conversations_create_own on dns_support.conversations;
create policy support_conversations_create_own on dns_support.conversations for insert to authenticated
with check(participant_user_id=(select auth.uid()) and assigned_agent_id is null and status='open' and private.has_live_auth_session());
drop policy if exists support_conversations_read_participant_or_staff on dns_support.conversations;
create policy support_conversations_read_participant_or_staff on dns_support.conversations for select to authenticated
using((participant_user_id=(select auth.uid()) and private.has_live_auth_session() and exists(select 1 from public.exchange_profiles p where p.user_id=(select auth.uid()) and p.deleted_at is null)) or private.is_active_support_admin());
drop policy if exists support_messages_insert_participant_or_staff on dns_support.messages;
create policy support_messages_insert_participant_or_staff on dns_support.messages for insert to authenticated
with check(sender_user_id=(select auth.uid()) and (
 (internal_note=false and sender_role in ('buyer','supplier') and private.has_live_auth_session() and exists(
  select 1 from dns_support.conversations c join public.exchange_profiles p on p.user_id=c.participant_user_id
  where c.id=conversation_id and c.participant_user_id=(select auth.uid()) and p.deleted_at is null and p.account_type=sender_role and p.account_status in ('pending','active')
 ))
 or (sender_role in ('agent','supervisor','admin') and private.is_active_support_admin())
));
drop policy if exists support_messages_read_participant_or_staff on dns_support.messages;
create policy support_messages_read_participant_or_staff on dns_support.messages for select to authenticated
using(exists(select 1 from dns_support.conversations c where c.id=conversation_id and (
 (c.participant_user_id=(select auth.uid()) and private.has_live_auth_session() and exists(select 1 from public.exchange_profiles p where p.user_id=(select auth.uid()) and p.deleted_at is null))
 or private.is_active_support_admin()
)) and (internal_note=false or private.is_active_support_admin()));
