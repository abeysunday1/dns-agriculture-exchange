-- Staging-only verification surface: anon has table privilege, but RLS explicitly denies reads.
grant select on public.exchange_submissions to anon;
drop policy if exists exchange_submissions_anon_deny on public.exchange_submissions;
create policy exchange_submissions_anon_deny on public.exchange_submissions
for select to anon using(false);
