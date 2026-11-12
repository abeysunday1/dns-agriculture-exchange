-- Reconstructed from the existing production migration ledger for isolated staging.
-- CRM-only objects and the production webhook secret are deliberately excluded.
create schema if not exists dns_support;
create schema if not exists private;

create table if not exists dns_support.support_agents (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('agent','supervisor','admin')),
  display_name text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists dns_support.conversations (
  id uuid primary key default gen_random_uuid(),
  ticket_ref text not null unique,
  participant_user_id uuid not null references auth.users(id) on delete restrict,
  participant_type text not null check (participant_type in ('buyer','supplier')),
  subject text not null check (char_length(subject) between 3 and 160),
  category text not null default 'general',
  status text not null default 'open' check (status in ('open','pending','resolved','closed')),
  priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  assigned_agent_id uuid references auth.users(id) on delete set null,
  last_message_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists dns_support.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references dns_support.conversations(id) on delete cascade,
  sender_user_id uuid not null references auth.users(id) on delete restrict,
  sender_role text not null check (sender_role in ('buyer','supplier','agent','supervisor','admin')),
  body text not null check (char_length(body) between 1 and 5000),
  attachment_path text,
  internal_note boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists support_conversations_owner_idx on dns_support.conversations(participant_user_id,last_message_at desc);
create index if not exists support_conversations_agent_idx on dns_support.conversations(assigned_agent_id,status,last_message_at desc);
create index if not exists support_messages_conversation_idx on dns_support.messages(conversation_id,created_at);
alter table dns_support.support_agents enable row level security;
alter table dns_support.conversations enable row level security;
alter table dns_support.messages enable row level security;
drop policy if exists support_agents_read_self on dns_support.support_agents;
create policy support_agents_read_self on dns_support.support_agents for select to authenticated using (user_id=auth.uid());
drop policy if exists support_conversations_read_participant_or_staff on dns_support.conversations;
create policy support_conversations_read_participant_or_staff on dns_support.conversations for select to authenticated using (
 participant_user_id=auth.uid() or exists(select 1 from dns_support.support_agents a where a.user_id=auth.uid() and a.active=true)
);
drop policy if exists support_conversations_create_own on dns_support.conversations;
create policy support_conversations_create_own on dns_support.conversations for insert to authenticated with check (
 participant_user_id=auth.uid() and assigned_agent_id is null and status='open'
);
drop policy if exists support_conversations_update_staff on dns_support.conversations;
create policy support_conversations_update_staff on dns_support.conversations for update to authenticated using (
 exists(select 1 from dns_support.support_agents a where a.user_id=auth.uid() and a.active=true)
) with check (exists(select 1 from dns_support.support_agents a where a.user_id=auth.uid() and a.active=true));
drop policy if exists support_messages_read_participant_or_staff on dns_support.messages;
create policy support_messages_read_participant_or_staff on dns_support.messages for select to authenticated using (
 exists(select 1 from dns_support.conversations c where c.id=conversation_id and (
 c.participant_user_id=auth.uid() or exists(select 1 from dns_support.support_agents a where a.user_id=auth.uid() and a.active=true)))
 and (internal_note=false or exists(select 1 from dns_support.support_agents a where a.user_id=auth.uid() and a.active=true))
);
drop policy if exists support_messages_insert_participant_or_staff on dns_support.messages;
create policy support_messages_insert_participant_or_staff on dns_support.messages for insert to authenticated with check (
 sender_user_id=auth.uid() and (
 (internal_note=false and exists(select 1 from dns_support.conversations c where c.id=conversation_id and c.participant_user_id=auth.uid() and sender_role in ('buyer','supplier')))
 or (exists(select 1 from dns_support.support_agents a where a.user_id=auth.uid() and a.active=true) and sender_role in ('agent','supervisor','admin'))
));
create or replace function dns_support.set_ticket_ref() returns trigger language plpgsql set search_path='' as $$
begin
 if new.ticket_ref is null or new.ticket_ref='' then
  new.ticket_ref := 'DNS-'||to_char(now(),'YYMMDD')||'-'||upper(substr(encode(gen_random_bytes(5),'hex'),1,8));
 end if;
 return new;
end; $$;
drop trigger if exists support_ticket_ref_before_insert on dns_support.conversations;
create trigger support_ticket_ref_before_insert before insert on dns_support.conversations for each row execute function dns_support.set_ticket_ref();
create or replace function dns_support.touch_conversation() returns trigger language plpgsql set search_path='' as $$
begin
 update dns_support.conversations set last_message_at=new.created_at,updated_at=now() where id=new.conversation_id;
 return new;
end; $$;
drop trigger if exists support_message_touch_conversation on dns_support.messages;
create trigger support_message_touch_conversation after insert on dns_support.messages for each row execute function dns_support.touch_conversation();
grant usage on schema dns_support to authenticated;
grant select,insert,update on dns_support.conversations to authenticated;
grant select,insert on dns_support.messages to authenticated;
grant select on dns_support.support_agents to authenticated;
do $$ begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='dns_support' and tablename='messages') then alter publication supabase_realtime add table dns_support.messages; end if;
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='dns_support' and tablename='conversations') then alter publication supabase_realtime add table dns_support.conversations; end if;
end $$;

create table if not exists public.exchange_profiles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 full_name text,
 account_type text not null check(account_type in ('buyer','supplier')),
 account_status text not null default 'pending' check(account_status in ('pending','active','suspended')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.exchange_profiles enable row level security;
revoke all on public.exchange_profiles from anon,authenticated;
grant select on public.exchange_profiles to authenticated;
drop policy if exists "Users read own exchange profile" on public.exchange_profiles;
create policy "Users read own exchange profile" on public.exchange_profiles for select to authenticated using(user_id=(select auth.uid()));
create or replace function public.handle_new_exchange_user() returns trigger language plpgsql security definer set search_path='' as $$
declare requested_role text;
begin
 requested_role:=coalesce(new.raw_user_meta_data->>'account_type','buyer');
 if requested_role not in ('buyer','supplier') then requested_role:='buyer'; end if;
 insert into public.exchange_profiles(user_id,full_name,account_type)
 values(new.id,nullif(trim(new.raw_user_meta_data->>'full_name'),''),requested_role)
 on conflict(user_id) do nothing;
 return new;
end; $$;
revoke all on function public.handle_new_exchange_user() from public,anon,authenticated;
drop trigger if exists on_auth_user_created_exchange_profile on auth.users;
create trigger on_auth_user_created_exchange_profile after insert on auth.users for each row execute function public.handle_new_exchange_user();

create table if not exists public.exchange_submissions (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 submission_type text not null check(submission_type in ('supplier','buyer')),
 submission_data jsonb not null default '{}'::jsonb,
 status text not null default 'pending_review' check(status in ('pending_review','under_review','approved','rejected','withdrawn')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists exchange_submissions_user_created_idx on public.exchange_submissions(user_id,created_at desc);
create index if not exists exchange_submissions_type_status_idx on public.exchange_submissions(submission_type,status,created_at desc);
alter table public.exchange_submissions enable row level security;
drop policy if exists exchange_submissions_insert_own on public.exchange_submissions;
create policy exchange_submissions_insert_own on public.exchange_submissions for insert to authenticated with check(
 user_id=(select auth.uid()) and exists(select 1 from public.exchange_profiles p where p.user_id=(select auth.uid()) and p.account_type=submission_type and p.account_status in ('pending','active'))
);
drop policy if exists exchange_submissions_select_own on public.exchange_submissions;
create policy exchange_submissions_select_own on public.exchange_submissions for select to authenticated using(user_id=(select auth.uid()));
grant select,insert on public.exchange_submissions to authenticated;
grant all on public.exchange_submissions to service_role;
drop policy if exists exchange_submissions_admin_read on public.exchange_submissions;
create policy exchange_submissions_admin_read on public.exchange_submissions for select to authenticated using(
 exists(select 1 from dns_support.support_agents a where a.user_id=(select auth.uid()) and a.active=true and a.role='admin')
);
drop policy if exists exchange_submissions_admin_update on public.exchange_submissions;
create policy exchange_submissions_admin_update on public.exchange_submissions for update to authenticated using(
 exists(select 1 from dns_support.support_agents a where a.user_id=(select auth.uid()) and a.active=true and a.role='admin')
) with check(exists(select 1 from dns_support.support_agents a where a.user_id=(select auth.uid()) and a.active=true and a.role='admin'));
grant select,update on public.exchange_submissions to authenticated;
do $$ begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='exchange_submissions') then alter publication supabase_realtime add table public.exchange_submissions; end if;
end $$;

create table if not exists public.exchange_automation_events (
 submission_id uuid primary key references public.exchange_submissions(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 submission_type text not null check(submission_type in ('buyer','supplier')),
 automation_status text not null default 'received' check(automation_status in ('received','queued_for_review','failed')),
 received_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.exchange_automation_events enable row level security;
revoke all on public.exchange_automation_events from anon,authenticated;
grant all on public.exchange_automation_events to service_role;
drop policy if exists exchange_automation_events_deny_clients on public.exchange_automation_events;
create policy exchange_automation_events_deny_clients on public.exchange_automation_events for all to anon,authenticated using(false) with check(false);

create or replace function private.is_active_support_admin() returns boolean language sql security definer set search_path='' as $$
 select exists(select 1 from dns_support.support_agents a where a.user_id=(select auth.uid()) and a.active=true and a.role='admin');
$$;
revoke all on function private.is_active_support_admin() from public,anon;
grant execute on function private.is_active_support_admin() to authenticated;
drop policy if exists support_agents_admin_list on dns_support.support_agents;
create policy support_agents_admin_list on dns_support.support_agents for select to authenticated using(private.is_active_support_admin());
