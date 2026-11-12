drop policy if exists exchange_submissions_admin_read on public.exchange_submissions;
create policy exchange_submissions_admin_read on public.exchange_submissions for select to authenticated using (
  exists (select 1 from dns_support.support_agents a where a.user_id = (select auth.uid()) and a.active = true and a.role = 'admin')
);
drop policy if exists exchange_submissions_admin_update on public.exchange_submissions;
create policy exchange_submissions_admin_update on public.exchange_submissions for update to authenticated using (
  exists (select 1 from dns_support.support_agents a where a.user_id = (select auth.uid()) and a.active = true and a.role = 'admin')
) with check (
  exists (select 1 from dns_support.support_agents a where a.user_id = (select auth.uid()) and a.active = true and a.role = 'admin')
);
grant select, update on public.exchange_submissions to authenticated;
create table if not exists public.exchange_automation_events (
  submission_id uuid primary key references public.exchange_submissions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  submission_type text not null check (submission_type in ('buyer','supplier')),
  automation_status text not null default 'received' check (automation_status in ('received','queued_for_review','failed')),
  received_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.exchange_automation_events enable row level security;
revoke all on public.exchange_automation_events from anon, authenticated;
grant all on public.exchange_automation_events to service_role;
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='exchange_submissions') then
    alter publication supabase_realtime add table public.exchange_submissions;
  end if;
end $$;
