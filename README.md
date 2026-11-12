# DNS Agriculture Exchange

A mobile-first buyer/supplier exchange for DigitalNewsSpace Agriculture.

## Current branch and release status

- Repair work is isolated on `fix/owner-registration-auth`.
- The production `main` branch and live site remain unchanged.
- A free-tier Supabase staging project is configured for the repair work.
- This branch includes email/password authentication, buyer and supplier submissions, an admin review queue, profile editing, deletion requests, Google OAuth wiring, and a server-side account-revocation function.
- Google OAuth is not enabled until a Google Web OAuth client is configured in the staging Supabase Auth provider.
- Browser acceptance tests have not yet been completed. Do not treat this branch as production-ready.

## Existing data model

- Buyer sourcing requests are `public.exchange_submissions` rows with `submission_type='buyer'`.
- Supplier produce submissions use the same table with `submission_type='supplier'`.
- Do not create a separate sourcing-requirements table.
- Support conversations/messages are in the `dns_support` schema.

## Security and staging

- Browser clients use a public Supabase publishable key only.
- Never place a service-role/secret key or SMTP credential in client code.
- Local Playwright can route pages to staging by setting `window.DNS_SUPABASE_CONFIG = { url, key }` with `page.addInitScript` before navigation.
- The default client configuration remains the existing production project; never run tests without the staging override.
- The account-deletion Edge Function runs server-side and reads the Supabase service-role key from the Edge Function environment.

## Documentation

- [Supabase setup and Google OAuth](supabase/README.md)
- [Zero-cost operations and release runbook](docs/runbook.md)

## Local preview

Serve the repository root on `http://127.0.0.1:5500` and open `login.html`. For staging tests, inject the staging URL and publishable key before page scripts execute. Do not use the live GitHub Pages site for acceptance tests.
