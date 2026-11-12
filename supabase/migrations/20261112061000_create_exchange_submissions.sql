create table if not exists public.exchange_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  submission_type text not null check (submission_type in ('supplier','buyer')),
  submission_data jsonb not null default '{}'::jsonb,
  status text not null default 'pending_review' check (status in ('pending_review','under_review','approved','rejected','withdrawn')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists exchange_submissions_user_created_idx on public.exchange_submissions(user_id, created_at desc);
create index if not exists exchange_submissions_type_status_idx on public.exchange_submissions(submission_type, status, created_at desc);
alter table public.exchange_submissions enable row level security;
drop policy if exists exchange_submissions_insert_own on public.exchange_submissions;
create policy exchange_submissions_insert_own on public.exchange_submissions for insert to authenticated with check (
  user_id = (select auth.uid()) and exists (
    select 1 from public.exchange_profiles p where p.user_id = (select auth.uid()) and p.account_type = submission_type and p.account_status in ('pending','active')
  )
);
drop policy if exists exchange_submissions_select_own on public.exchange_submissions;
create policy exchange_submissions_select_own on public.exchange_submissions for select to authenticated using (user_id = (select auth.uid()));
grant select, insert on public.exchange_submissions to authenticated;
grant all on public.exchange_submissions to service_role;
