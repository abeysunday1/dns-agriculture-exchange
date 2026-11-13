# DNS Agriculture Exchange — Staging Audit
**Audit date:** 13 November 2026  
**Scope:** GitHub repository `abeysunday1/dns-agriculture-exchange`, Supabase project `DNS Agriculture Exchange Staging` (`lvpgasxdmzpsjprohcji`), frontend source, database metadata, RLS policies, migrations, Edge Functions and Supabase security/performance advisors.  
**Method:** Read-only inspection. No production data or schema was changed during this audit.

## Executive result

The project has a working prototype and a meaningful buyer/supplier database foundation, but it is not yet a production-ready multi-role agricultural exchange. Several screens are explicitly demo-only, important forms do not persist data, the support frontend points to a different Supabase project, and the current database only models buyer/supplier accounts.

## 1. Repository and environment

- Repository: https://github.com/abeysunday1/dns-agriculture-exchange
- Default branch: `main`; current audited commit: `2f504fd8c4f5fada1f5b61847b267f86d585f19f`.
- GitHub Pages is enabled for the repository. The default branch is not protected.
- A separate work branch was created for this audit and follow-up staging work: `staging/dns-exchange-audit-2026-11-13`.
- Supabase staging project: `lvpgasxdmzpsjprohcji`; status `ACTIVE_HEALTHY`; region `eu-central-1`; PostgreSQL 17.11.
- A second Supabase project exists in the account (`zwvtxybqvxtnjrhfcptt)); the support frontend currently references this second project.

## 2. Frontend implementation verified

Tracked frontend files include `index.html`, `buyer.html`, `login.html`, `admin.html`, `support-agent.html` and `support-live.js`, alongside architecture documentation.

### Working or wired behavior
- Responsive HTML/CSS layouts and client-side navigation.
- Login page calls Supabase Auth for email/password sign-in, sign-up, password recovery and Google OAuth.
- Login reads `exchange_profiles.account_type` and routes buyers to `buyer.html`; the other supported account path goes to `index.html`.
- Support JavaScript contains Supabase-backed sign-in, conversation/message reads and writes, and realtime subscription logic.

### Demo-only or incomplete behavior
- Farmer/supplier dashboard figures, listings and statuses are sample data.
- Buyer dashboard requirements, offers and deals are sample data.
- Supplier onboarding form displays a demo alert; it does not save the submission.
- Buyer requirement form is client-side only; it does not save the requirement.
- Admin support queue explicitly identifies itself as a preview without live admin authentication or persistent actions.
- The two participant portals are not protected by a complete route/session guard in their page source. Client-side page routing is not authorization.

## 3. Current role coverage

The login page only offers buyer and supplier role selection. The database constraint on `exchange_profiles.account_type` also only permits `buyer` and `supplier`.

The following requested portals are not implemented as separate authenticated portals:
- Farmer (the current supplier-branded workspace is not a distinct farmer portal)
- Farm owner
- Farmland owner
- Investor
- Processor
- Exporter
- Agent
- Protected central administrator portal

The target role model must be implemented through server-enforced role assignment and database permissions, not client-side role selection or user-editable metadata.

## 4. Supabase staging database inventory

The staging project currently has 15 listed application tables across `public` and `dns_support`. All listed tables have RLS enabled.

### Public schema
- `exchange_profiles`
- `exchange_submissions`
- `exchange_automation_events`
- `account_deletion_requests`
- `buyer_prospects`
- `buyer_interactions`
- `buyer_opportunities`
- `buyer_samples`
- `buyer_orders`
- `buyer_supply_matches`
- `buyer_quality_feedback`
- `Task`

### Support schema
- `dns_support.support_agents`
- `dns_support.conversations`
- `dns_support.messages`

The returned table row estimates showed one row in `exchange_profiles` and zero rows in the other listed tables at audit time. Treat these as staging inventory results, not production activity metrics.

### Existing business capabilities in the database
- Buyer/supplier account profiles and submissions.
- Submission review and automation event tracking.
- Buyer prospect CRM and interaction history.
- Buyer commodity opportunities and specifications.
- Paid sample and courier tracking.
- Buyer orders with payment, quality and fulfilment status fields.
- Buyer-to-supplier matching and buyer quality feedback.
- Customer-support conversations and messages.
- Account deletion request and revocation workflow.

The buyer CRM/order schema is a useful foundation, but it is not yet the full DNS commodity trading ledger or all-role marketplace schema.

## 5. Important database permission findings

- RLS is enabled on all 15 listed application tables.
- Buyer CRM tables currently have administrator-only policies; no buyer self-service policies were found for the buyer prospect/opportunity/order tables. This means the current schema does not yet provide the intended direct buyer portal access.
- `exchange_profiles` supports self-read and self-update subject to account/session checks.
- `exchange_submissions` supports own submission creation/read and administrator review.
- Support conversations/messages have participant/staff policies, including internal-note visibility restrictions.
- `public.Task` has RLS enabled but no policies. The Supabase advisor flags it. If unused, confirm its purpose and remove it through a reviewed migration; otherwise define the intended policy.
- No Storage buckets are currently configured in the staging project.

## 6. Functions, triggers and migrations

- One active Edge Function was found: `revoke-deleted-account`, with JWT verification enabled. It checks administrator status and approved deletion requests before deleting the Auth user.
- The database contains profile bootstrap, session-check, support-admin, account-deletion, buyer-tier and paid-stage helper functions.
- Existing triggers handle support ticket references, conversation updates, account-deletion review, buyer CRM timestamps and paid-buyer stage synchronization.
- Twelve migrations were recorded, covering the exchange baseline, profile/deletion flows, Google OAuth bootstrap, session revocation, security-definer hardening, buyer CRM, paid-trial integrity, market tiers, indexes and privilege hardening.

## 7. Authentication and security configuration

Verified staging Auth settings:
- Email/password authentication enabled.
- Google OAuth enabled.
- TOTP MFA enrollment and verification enabled.
- Email confirmation required; auto-confirm is disabled.
- Leaked-password protection is disabled.
- CAPTCHA is disabled.
- Configured Auth site URL is still `http://127.0.0.1:5500`; the redirect allow-list includes localhost and the GitHub Pages project URL.
- Documentation in the repository records a Google OAuth redirect mismatch as an unresolved issue.

Do not publish or copy any service-role/secret key into browser code. Only the publishable/anon key belongs in a browser client, with RLS and least-privilege policies providing the actual data boundary.

## 8. Supabase advisor findings

### Security
1. Warning: leaked-password protection is disabled.
2. Informational finding: `public.Task` has RLS enabled but no policy.

### Performance
1. Three unindexed foreign keys were reported.
2. Two RLS policies were reported as re-evaluating Auth functions per row.
3. Three tables were reported with multiple permissive policies for the same action.
4. Several unused-index notices were reported; these should not be removed until workload and query plans are understood.

### Health
- No health-advisor findings were returned at audit time.

## 9. Integration findings

- Main login page points to the DNS staging Supabase project.
- `support-live.js` points to the other Supabase project, not the DNS staging project. The support schema exists in staging, so this project mismatch must be reconciled before relying on a shared account/support experience.
- No payment gateway, Google Maps, SMS/WhatsApp provider, or logistics API integration was found in the inspected frontend files.
- No Storage buckets exist yet.
- Email delivery configuration and OAuth redirect behavior need end-to-end testing.

## 10. Prioritized implementation plan

### P0 — Resolve before real users or transactions
1. Reconcile the support frontend with the intended staging Supabase project and confirm the correct publishable key.
2. Inspect and harden `ensure_exchange_profile_from_metadata`; prevent users from self-assigning elevated or unsupported roles.
3. Add session and role guards to every portal, backed by database RLS (never rely on hidden navigation).
4. Replace the unauthenticated preview admin screen with a protected staff/admin portal before exposing real records.
5. Enable leaked-password protection in staging and verify signup behavior.
6. Fix and test Google OAuth redirect URLs for the actual staging origin.
7. Review the `Task` table and resolve its no-policy finding.
8. Verify RLS policies and grants with separate test accounts for each role.

### P1 — Make the existing core usable
1. Persist farmer/supplier submissions and buyer requirements.
2. Add authenticated buyer and supplier profile reads/updates.
3. Implement purchase/sales order lifecycle and audit trail.
4. Implement payment gateway verification, idempotency and reconciliation before farmer settlement.
5. Add private document storage with scoped Storage policies.
6. Implement notifications and operational support.

### P2 — Expand the ecosystem
1. Add farmer, farm owner, farmland owner, investor, processor, exporter and agent role models/portals.
2. Add commodity catalogue, offer/counteroffer, group buying, inventory, quality inspection, warehouse, logistics and delivery tracking.
3. Add investment project disclosures and reporting with legal review.
4. Add market intelligence and AI recommendations only after reliable transaction data exists.

## 11. Guardrails for follow-up work

- Continue only on `staging/dns-exchange-audit-2026-11-13` and the Supabase staging project.
- Do not alter `main`, production configuration or production data.
- Preserve existing buyer/supplier functionality and migration history.
- Use additive, reversible migrations where possible.
- Do not enable payment collection or investor funding until contracts, reconciliation, authorization and test cases pass.
- Record each change, run tests, and report what is implemented versus merely planned.

**Audit conclusion:** DNS has a useful buyer/supplier prototype and a secured database foundation, but the application remains a demonstration with incomplete end-to-end workflows. The immediate priority is identity/project consistency, authorization and data persistence—not adding more visual portals before the underlying permissions and transaction engine are sound.
