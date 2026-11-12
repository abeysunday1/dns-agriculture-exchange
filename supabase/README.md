# Supabase project operations

## Environments

- Production: `zwvtxybqvxtnjrhfcptt`. Read-only during this repair. Do not apply migrations, create test users, provision admins, or deploy Edge Functions here.
- Staging: `lvpgasxdmzpsjprohcji`, `https://lvpgasxdmzpsjprohcji.supabase.co`. Created on the free tier at **$0/month**. All test schema and Edge Function work is isolated here.
- No paid Supabase development branch was created. The local Docker path was unavailable in the execution environment.

## Migration inventory and staging baseline

The repair branch originally contained only `20261112080000_profile_and_account_deletion.sql`. Production's migration ledger contained nine historical entries; the CRM-only privilege migration and the migration containing the production webhook secret were not copied into staging. The exchange/support schema was reconstructed without production data or secrets in:

- `20261112070000_dns_exchange_staging_baseline.sql`
- `20261112080000_profile_and_account_deletion.sql`
- `20261112090000_google_oauth_profile_bootstrap.sql`
- `20261112091000_auth_session_revocation.sql`
- `20261112092000_harden_security_definer_rpc.sql`

The staging-only admin seed is separate: `supabase/staging-migrations/20261112090500_provision_staging_admins.sql`. Apply it only after the two staging Auth users exist. Never apply it to production.

Buyer sourcing requirements remain in `public.exchange_submissions` with `submission_type='buyer'`; do not create a parallel sourcing table.

## Google OAuth (staging first)

The UI calls Supabase's built-in Google provider. The provider is **not enabled yet** because no Google OAuth client ID/secret is configured.

1. In Google Cloud Console, create an OAuth client of type **Web application** (no paid Google service is required for this OAuth client).
2. Add this exact Authorized redirect URI:
   `https://lvpgasxdmzpsjprohcji.supabase.co/auth/v1/callback`
3. Add local development origins:
   `http://127.0.0.1:5500` and `http://localhost:5500`.
4. In Supabase staging > Authentication > Providers > Google, enter the client ID and client secret and enable Google.
5. Staging Auth Site URL is `http://127.0.0.1:5500`. Allowed redirects include `http://127.0.0.1:5500/**`, `http://localhost:5500/**`, and the existing GitHub Pages origin.
6. Keep the Google client secret in Supabase Auth settings only. Never commit it or place it in browser code, screenshots, or chat.

The exact staging client environment values are supplied at runtime, not committed. All browser client files accept an optional `window.DNS_SUPABASE_CONFIG = { url, key }` override; local Playwright must set it with `page.addInitScript` before navigation so no staging test can fall back to production. Without the override, existing production defaults remain unchanged:

- `SUPABASE_URL=https://lvpgasxdmzpsjprohcji.supabase.co`
- `SUPABASE_PUBLISHABLE_KEY=<staging publishable key>`
- `SUPABASE_SERVICE_ROLE_KEY=<server-side secret only; Edge Functions>`

Email/password signup continues to pass `account_type` metadata. A first-time Google user selects buyer or supplier after OAuth; `ensure_exchange_profile_from_metadata()` creates the profile once. Returning Google users route from the saved profile.

## Admin provisioning

Only one owner-approved staging identity is listed in `supabase/staging-migrations/20261112090500_provision_staging_admins.sql`: `adisaabiodunsunday@gmail.com`. The migration is idempotent and only seeds this account if it already exists in staging `auth.users`. Create and confirm the owner's staging Auth account first, then apply this migration to staging only. Do not copy the admin row to production.

## Account deletion and session revocation

Admin approval first soft-deletes the exchange profile. The browser then invokes the JWT-protected `revoke-deleted-account` Edge Function. It verifies the caller with `is_exchange_admin()`, verifies the request is approved, and calls `auth.admin.deleteUser(user_id)` using `SUPABASE_SERVICE_ROLE_KEY` from the server environment.

Supabase's admin sign-out endpoint requires the target user's JWT, not a user ID. Deleting the Auth user removes its sessions and refresh tokens; the staging RLS policies additionally check the current `auth.sessions` row so already-issued access JWTs cannot access protected exchange data while they remain unexpired. The deletion request retains an audit row with a null user reference.

## Security boundaries

- Browser code may contain only the publishable key. Never put a service-role/secret key, SMTP credential, or private API token in client files.
- Do not trust user-editable metadata for admin authorization. Admin role lives in `dns_support.support_agents`.
- The public admin RPC is invoker-only; privileged checks live in the unexposed `private` schema.
- The production Security Advisor previously reported leaked-password protection disabled. The free tier rejects enabling HaveIBeenPwned protection (HTTP 402; Pro-only). Do not upgrade or pay; this remains a documented release blocker.
- Staging RLS Security Advisor is clean after the corrective RPC migration. This is not a substitute for anon-key and cross-user runtime tests.
