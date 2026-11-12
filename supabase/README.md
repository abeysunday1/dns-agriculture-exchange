# Supabase project operations

## Environments

- Production project: `zwvtxybqvxtnjrhfcptt` (existing project). Do not use it for test accounts, destructive tests, or admin provisioning.
- Staging: not yet created. A Supabase development branch is billed hourly; obtain owner approval for the quoted rate before creating it. A new branch starts without production data.
- Apply and verify migrations in staging before any production change. Do not merge a Supabase branch into production as part of this repair.

## Migrations

Migrations are ordered SQL files under `supabase/migrations/`. They must be safe to re-run (`IF NOT EXISTS`, guarded policy/trigger replacement, and conflict-safe seeds). The profile/deletion migration is currently prepared for staging review only and has not been applied to production.

## Provisioning administrators

Admin access is granted only to a verified, explicitly approved account through a reviewed SQL migration in **staging**. Never expose an admin toggle in the browser, user-editable metadata, or public signup form. The role table is `dns_support.support_agents`; the admin console checks `private.is_active_support_admin()` through the `public.is_exchange_admin()` RPC.

Before provisioning:

1. Obtain explicit owner approval for the named owner account and the separate test-admin email.
2. Confirm both accounts exist in staging `auth.users` and their email addresses are verified.
3. Add an idempotent migration that inserts `user_id`, `role='admin'`, `active=true`, and a display name into `dns_support.support_agents`, using `ON CONFLICT (user_id) DO UPDATE` only after confirming the intended role changes.
4. Apply that migration to staging only; verify both admins can access the review queue and a buyer/supplier cannot.
5. Do not copy staging admin rows to production automatically. Production provisioning requires a separate owner decision and change review.

## Security boundaries

- Browser code may contain only the Supabase publishable key. Never put a service-role key, SMTP credential, or private API token in client files, Git history, screenshots, or logs.
- Account deletion is a request and approval process. It soft-deletes the exchange profile; it does not immediately erase the Auth identity or guarantee erasure of legally retained records.
- Buyer sourcing requests are stored as `exchange_submissions` with `submission_type='buyer'`; there is no separate `sourcing_requirements` table in the current schema.
