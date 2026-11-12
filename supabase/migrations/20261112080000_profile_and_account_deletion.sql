-- T5/T6: profile editing and request-based account deletion.
-- Safe to re-run. This file is committed for staging review; do not apply to production as part of this repair.

alter table public.exchange_profiles
  add column if not exists phone text,
  add column if not exists business_name text,
  add column if not exists location text,
  add column if not exists produce_categories text[] not null default '{}',
  add column if not exists deleted_at timestamptz;

-- Expose a narrow admin-check RPC so the browser does not need the dns_support schema exposed.
create or replace function public.is_exchange_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_active_support_admin();
$$;
revoke all on function public.is_exchange_admin() from public, anon;
grant execute on function public.is_exchange_admin() to authenticated;

-- Profile users may update only editable profile fields. They cannot self-promote,
-- change account status, or clear a soft-delete marker.
revoke update on table public.exchange_profiles from anon, authenticated;
grant select on table public.exchange_profiles to authenticated;
grant update (full_name, phone, business_name, location, produce_categories, updated_at)
  on table public.exchange_profiles to authenticated;

drop policy if exists "Users read own exchange profile" on public.exchange_profiles;
create policy "Users read active own exchange profile"
  on public.exchange_profiles for select to authenticated
  using (user_id = (select auth.uid()) and deleted_at is null);

do $$ begin
  if not exists (select 1 from pg_constraint where conrelid='public.exchange_profiles'::regclass and conname='exchange_profiles_profile_fields_length_check') then
    alter table public.exchange_profiles add constraint exchange_profiles_profile_fields_length_check
      check (
        (full_name is null or char_length(full_name) <= 120)
        and (phone is null or char_length(phone) <= 40)
        and (business_name is null or char_length(business_name) <= 160)
        and (location is null or char_length(location) <= 200)
        and cardinality(produce_categories) <= 30
        and char_length(array_to_string(produce_categories, ',')) <= 500
      );
  end if;
end $$;

drop policy if exists exchange_profiles_update_own on public.exchange_profiles;
create policy exchange_profiles_update_own
  on public.exchange_profiles for update to authenticated
  using (user_id = (select auth.uid()) and deleted_at is null and account_status in ('pending','active'))
  with check (user_id = (select auth.uid()) and deleted_at is null and account_status in ('pending','active'));

-- A buyer's sourcing request is stored as submission_type='buyer' in
-- exchange_submissions; do not create a duplicate sourcing_requirements table.
drop policy if exists exchange_submissions_select_own on public.exchange_submissions;
create policy exchange_submissions_select_own
  on public.exchange_submissions for select to authenticated
  using (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.exchange_profiles p
      where p.user_id = (select auth.uid()) and p.deleted_at is null
    )
  );

-- Anonymous database clients cannot read or write submissions. Signup is handled by Supabase Auth.
revoke all on table public.exchange_submissions from anon;
grant select, insert, update on table public.exchange_submissions to authenticated;

create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  reason text check (reason is null or char_length(reason) <= 1000),
  status text not null default 'pending'
    check (status in ('pending','approved','rejected')),
  admin_note text check (admin_note is null or char_length(admin_note) <= 1000),
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists account_deletion_requests_user_created_idx
  on public.account_deletion_requests(user_id, created_at desc);
create unique index if not exists account_deletion_requests_one_pending_per_user
  on public.account_deletion_requests(user_id) where status = 'pending';

alter table public.account_deletion_requests enable row level security;
revoke all on table public.account_deletion_requests from anon, authenticated;
grant select on table public.account_deletion_requests to authenticated;
grant insert (reason) on table public.account_deletion_requests to authenticated;
grant update (status, admin_note) on table public.account_deletion_requests to authenticated;

drop policy if exists account_deletion_requests_read_own on public.account_deletion_requests;
create policy account_deletion_requests_read_own
  on public.account_deletion_requests for select to authenticated
  using (user_id = (select auth.uid()));
drop policy if exists account_deletion_requests_insert_own on public.account_deletion_requests;
create policy account_deletion_requests_insert_own
  on public.account_deletion_requests for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and status = 'pending'
    and exists (
      select 1 from public.exchange_profiles p
      where p.user_id = (select auth.uid())
        and p.deleted_at is null
        and p.account_status in ('pending','active')
    )
  );
drop policy if exists account_deletion_requests_admin_read on public.account_deletion_requests;
create policy account_deletion_requests_admin_read
  on public.account_deletion_requests for select to authenticated
  using (private.is_active_support_admin());
drop policy if exists account_deletion_requests_admin_update on public.account_deletion_requests;
create policy account_deletion_requests_admin_update
  on public.account_deletion_requests for update to authenticated
  using (private.is_active_support_admin())
  with check (private.is_active_support_admin());

create or replace function public.handle_account_deletion_review()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status is distinct from old.status then
    if old.status <> 'pending' or new.status not in ('approved','rejected') then
      raise exception 'Only pending deletion requests may be approved or rejected';
    end if;
    new.reviewed_at := now();
    new.reviewed_by := auth.uid();
    new.updated_at := now();
    if new.status = 'approved' then
      update public.exchange_profiles
         set deleted_at = coalesce(deleted_at, now()), updated_at = now()
       where user_id = new.user_id;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists account_deletion_review_trigger on public.account_deletion_requests;
create trigger account_deletion_review_trigger
  before update on public.account_deletion_requests
  for each row execute function public.handle_account_deletion_review();


-- A soft-deleted account must also lose access to its private support tickets/messages.
drop policy if exists support_conversations_create_own on dns_support.conversations;
create policy support_conversations_create_own
  on dns_support.conversations for insert to authenticated
  with check (
    participant_user_id = (select auth.uid())
    and assigned_agent_id is null
    and status = 'open'
    and exists (
      select 1 from public.exchange_profiles p
      where p.user_id = (select auth.uid())
        and p.account_type = participant_type
        and p.account_status in ('pending','active')
        and p.deleted_at is null
    )
  );

drop policy if exists support_conversations_read_participant_or_staff on dns_support.conversations;
create policy support_conversations_read_participant_or_staff
  on dns_support.conversations for select to authenticated
  using (
    (
      participant_user_id = (select auth.uid())
      and exists (
        select 1 from public.exchange_profiles p
        where p.user_id = (select auth.uid()) and p.deleted_at is null
      )
    )
    or exists (
      select 1 from dns_support.support_agents a
      where a.user_id = (select auth.uid()) and a.active = true
    )
  );

drop policy if exists support_messages_insert_participant_or_staff on dns_support.messages;
create policy support_messages_insert_participant_or_staff
  on dns_support.messages for insert to authenticated
  with check (
    sender_user_id = (select auth.uid())
    and (
      (
        internal_note = false
        and sender_role in ('buyer','supplier')
        and exists (
          select 1 from dns_support.conversations c
          join public.exchange_profiles p on p.user_id = c.participant_user_id
          where c.id = conversation_id
            and c.participant_user_id = (select auth.uid())
            and p.deleted_at is null
            and p.account_type = sender_role
            and p.account_status in ('pending','active')
        )
      )
      or (
        sender_role in ('agent','supervisor','admin')
        and exists (
          select 1 from dns_support.support_agents a
          where a.user_id = (select auth.uid()) and a.active = true
        )
      )
    )
  );

drop policy if exists support_messages_read_participant_or_staff on dns_support.messages;
create policy support_messages_read_participant_or_staff
  on dns_support.messages for select to authenticated
  using (
    exists (
      select 1 from dns_support.conversations c
      where c.id = conversation_id
        and (
          (
            c.participant_user_id = (select auth.uid())
            and exists (
              select 1 from public.exchange_profiles p
              where p.user_id = (select auth.uid()) and p.deleted_at is null
            )
          )
          or exists (
            select 1 from dns_support.support_agents a
            where a.user_id = (select auth.uid()) and a.active = true
          )
        )
    )
    and (
      internal_note = false
      or exists (
        select 1 from dns_support.support_agents a
        where a.user_id = (select auth.uid()) and a.active = true
      )
    )
  );
