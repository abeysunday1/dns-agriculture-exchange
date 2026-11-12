# DNS Agriculture Exchange — Operations Runbook

## Current release state

- Active repair branch: `fix/owner-registration-auth`.
- Production `main`: unchanged; live site has not been deployed or modified.
- Production Supabase: `zwvtxybqvxtnjrhfcptt` — read-only during this repair.
- Free staging: `lvpgasxdmzpsjprohcji` (`https://lvpgasxdmzpsjprohcji.supabase.co`), created at **$0/month**.
- No paid tools, paid branches, upgrades, or Firecrawl credits were used. No PR is open.

## Local Supabase testing (preferred $0 route)

1. Install Docker Desktop and the Supabase CLI locally.
2. From the repository root, run:
   ```bash
   supabase start
   supabase status
   ```
3. Apply the migrations and seed only disposable local test data:
   ```bash
   supabase db reset
   ```
4. Supabase local Auth emails are captured by Inbucket. Open the URL shown by `supabase status` (normally `http://127.0.0.1:54324`) to inspect confirmation and password-reset messages.
5. Stop local services with `supabase stop`.

This execution environment did not contain Docker or the Supabase CLI, so the free-tier staging project was used instead.

## Staging environment variables

Set these in the local test process, not in Git:

- `SUPABASE_URL=https://lvpgasxdmzpsjprohcji.supabase.co`
- `SUPABASE_PUBLISHABLE_KEY=<staging publishable key>`
- `SUPABASE_SERVICE_ROLE_KEY=<server-only secret; never expose to browser>`

The Edge Function reads Supabase's server-side environment. Never paste secret values into code, logs, screenshots, or chat.

## Google OAuth setup

Google is additive; email/password remains supported.

1. Create a Google OAuth **Web application** client.
2. Authorized redirect URI:
   `https://lvpgasxdmzpsjprohcji.supabase.co/auth/v1/callback`
3. Authorized JavaScript origins for local testing:
   `http://127.0.0.1:5500` and `http://localhost:5500`.
4. In Supabase staging > Authentication > Providers > Google, save the client ID and secret and enable the provider.
5. Staging Site URL: `http://127.0.0.1:5500`; allowed redirect URLs include the local origins and the GitHub Pages origin.
6. Do not add the Google client secret to the repository. Provider remains disabled until the client credentials are entered.

## Admin provisioning

1. Create and confirm the two approved accounts in staging Auth.
2. Apply `supabase/staging-migrations/20261112090500_provision_staging_admins.sql` to staging only.
3. Verify the owner and test admin can access `admin.html`; buyer, supplier, and signed-out users must be denied.
4. Never apply the staging seed to production.

## Key rotation

1. Identify whether the affected credential is publishable or secret.
2. Replace server-side secrets first; update Edge Function secrets/consumers without writing values into Git.
3. Update allowed deployment configuration and verify Auth, RLS, and Edge Functions in staging.
4. Revoke the old secret only after all consumers have moved. If a secret is exposed, revoke it immediately and inspect access logs.
5. Rotate SMTP credentials at the mail provider and update Auth SMTP settings securely.

## Rollback

1. Stop the release; do not merge or publish automatically.
2. Revert the specific repair commit on a new reviewed commit; do not force-push branch history.
3. For database changes, prefer a forward corrective migration. Do not assume a destructive down migration can restore deleted data.
4. Preserve screenshots and test evidence before resetting or deleting staging.
5. Never reset, merge, or apply a rollback to production as part of this repair.

## Live-site reachability check (curl, no Firecrawl)

Run from a network-enabled machine:

```bash
for path in /dns-agriculture-exchange/ \
  /dns-agriculture-exchange/login.html \
  /dns-agriculture-exchange/buyer.html \
  /dns-agriculture-exchange/index.html \
  /dns-agriculture-exchange/admin.html; do
  url="https://abeysunday1.github.io${path}"
  body="$(mktemp)"
  code="$(curl -L -sS --max-time 20 -o "$body" -w '%{http_code}' "$url")"
  printf '%s %s ' "$code" "$url"
  sha256sum "$body" | cut -d' ' -f1
  rm -f "$body"
done
date -Is
```

This execution environment could not resolve the public GitHub Pages hostname, so the reachability check returned DNS failures and no valid HTTP status/hash. Re-run from the owner's PC or another network-enabled host. Firecrawl was not used or retried.

## Activepieces inventory and notification workflow

Existing project: `Adisa's Project`.

- **DNS Agriculture — Exchange Submission Sync** — enabled. Authenticated webhook trigger; one Supabase upsert into `exchange_automation_events`, keyed by `submission_id`. It records receipt only; it does not send approval/rejection email.
- **Untitled** — enabled Supabase trigger for the unrelated CRM `activities` table.
- **DNS Agriculture — Buyer Form Intake** — disabled legacy Tables-based intake flow.
- **DNS Agriculture — Supplier Form Intake** — disabled legacy Tables-based intake flow.
- **DNS Agri — Consent-Gated Email Welcome** — disabled Tables-triggered flow.
- **Adisa Lead Discovery — Firecrawl to CRM (6-hour interim)** — disabled; do not enable or use Firecrawl.

Do not switch the existing submission-sync flow's production Supabase connection to staging. Approval/rejection notifications require a staging-safe event route and an isolated Gmail test; this is not yet verified. SLA target: first admin review within 24 hours of submission. Calendar integration is optional and not configured.

## Monitoring

- Inspect Supabase Auth, Postgres, API, and Edge Function logs for sign-in failures, RLS denials, insert/update errors, and function errors.
- Review Supabase Security and Performance Advisors after each migration.
- Check browser console errors and failed network requests during each acceptance flow.
- Keep screenshots, timestamps, test-user IDs, submission IDs, and relevant log excerpts in the release evidence folder; redact email addresses and tokens.
- Review pending submissions and account-deletion requests on the admin queue.

## Known free-tier blocker

Supabase rejected enabling leaked-password protection because HaveIBeenPwned checks are available on Pro plans and up. Do not upgrade or pay. The staging Security Advisor is clean after the RPC hardening migration, but this separate Auth control remains disabled and blocks the stated release gate.

## Release gate

Do not merge or publish until all eight browser flows have four evidence types each (screenshots, console logs, network statuses, and DB rows); Google OAuth passes end-to-end; anon and cross-user RLS tests pass; gitleaks/trufflehog history scan and client bundle scan are clean; account deletion revokes Auth sessions; Gmail approval/rejection notifications are proven through the existing flow; and responsive/accessibility checks pass at 375px and 768px.
