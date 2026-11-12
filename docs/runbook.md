# DNS Agriculture Exchange — Operations Runbook

## Current release state

- Work is isolated on `fix/owner-registration-auth`.
- Production Supabase project: `zwvtxybqvxtnjrhfcptt`.
- No staging project/branch exists at the time of this runbook update. The quoted development-branch rate is $0.01344/hour; do not create it without owner approval.
- The live GitHub Pages site and `main` branch have not been changed by this repair.
- Never call the release ready based on syntax checks alone. Browser evidence and database verification are mandatory.

## Provisioning an administrator

1. Obtain written approval naming the exact staging email(s).
2. Confirm the staging Auth users exist and are email-confirmed.
3. Commit an idempotent migration under `supabase/migrations/` that inserts the users into `dns_support.support_agents` as active admins. Do not grant privileges through client-side code or user metadata.
4. Apply only to staging, then verify admin access, non-admin denial, and signed-out denial in a real browser.
5. Keep production provisioning separate and explicitly approved.

## Key rotation

1. Identify whether the affected credential is publishable or secret. Publishable keys are expected in browser code; service-role/secret keys are not.
2. Create a replacement in Supabase project API settings and update server-side environment/secrets first.
3. Update any authorized deployment environment variables; never commit secret values.
4. Verify Auth, database access, and Edge Functions in staging.
5. Revoke the old secret only after all consumers have moved. If a secret was exposed, revoke it immediately and investigate access logs.
6. Rotate SMTP credentials in the mail provider, then update Supabase Auth SMTP settings or the server-side secret store. Do not put SMTP passwords in GitHub.

## Rollback

1. Stop the release; do not merge or deploy automatically.
2. For a GitHub Pages release, revert the specific release commit on a new reviewed commit and verify the previous page set before publishing.
3. For database changes, prefer a forward corrective migration. Do not assume a destructive down-migration can restore deleted data.
4. For Supabase development branches, reset/delete only the staging branch after preserving evidence. Never reset or merge production as a rollback shortcut.
5. Confirm login, protected-route denial, and submission reads after rollback.

## Monitoring

- Inspect Supabase Auth, Postgres, API, and Edge Function logs for sign-in failures, RLS denials, insert/update errors, and function errors.
- Review Supabase Security and Performance Advisors after every migration.
- Check the browser console and failed network requests during each acceptance flow.
- Keep screenshots, timestamps, test-user IDs, submission IDs, and relevant log excerpts in the release evidence folder/PR. Redact email addresses and tokens in screenshots.
- Review pending exchange submissions and account-deletion requests on the admin queue after admin provisioning is complete.

## Notification and SLA operations

Submission approval/rejection email notifications are not yet connected to a verified server-side workflow. Do not send messages from browser code or claim notifications are active. A Google Calendar SLA reminder is optional and should be created only after the owner selects the review target and cadence.

## Release gate

Do not merge until all eight auth/submission flows pass in a real browser against staging; RLS is tested with two distinct users and anon; admin denial is proven; profile edit and deletion request tests pass; no secrets are present in client code/history; two staging admins are provisioned; and evidence is attached to a reviewed PR.
