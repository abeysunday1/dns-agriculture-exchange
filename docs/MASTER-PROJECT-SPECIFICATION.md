# DNS Agriculture Exchange — Master Project Specification

**Status:** Authoritative working specification  
**Version:** 1.0  
**Last consolidated:** 13 November 2026  
**Repository:** `abeysunday1/dns-agriculture-exchange`  
**Canonical branch:** `main`

> This document is the single source of truth for product direction and delivery order. The supporting architecture, permissions, database-design and UX-research documents remain as detailed references. If a conflict appears, this master specification records the approved product decisions; implementation must still be checked against the actual code and staging database.

## 1. Product direction

DNS Agriculture Exchange is a multi-party agricultural commerce and operations platform connecting Nigerian and international participants. It must support the full trade journey—from verified onboarding and sourcing through quotations, orders, quality checks, dispatch, delivery and post-delivery records—not merely public produce listings.

**Non-negotiable product rule:** one user account has one selected primary role and one dedicated role-specific portal. The portal does not switch between buyer and farmer views. DNS central administration is the only cross-platform operational command centre.

## 2. Approved portals and roles

There are eight separate participant portals:

1. **Farmer Portal** — farm and crop profiles, production and harvest forecasts, produce listings, buyer enquiries, quotations, orders, dispatch and sales records.
2. **Buyer Portal** — commodity discovery, supplier search, purchase requirements/RFQs, quotations, negotiation, samples, purchase orders, delivery and payment records.
3. **Supplier Portal** — agricultural inputs/equipment catalogue, inventory, pricing, quotations, customer orders and fulfilment.
4. **Processor Portal** — raw-material requirements, facility/capacity records, procurement, production batches, quality control and finished inventory.
5. **Exporter Portal** — export catalogue/specifications, international enquiries, quotations/contracts, compliance documents and shipment milestones.
6. **Investor Portal** — verified opportunities, project information, funding enquiries, investment records and milestone reports.
7. **Farmland Owner Portal** — land listings, location/size, ownership-document verification, lease/sale enquiries and agreements.
8. **Agent Portal** — assigned leads, onboarding, verification progress, follow-ups, activities, commissions and performance.

**DNS Super Admin Portal:** restricted internal access for the platform owner and explicitly authorized administrators. It provides cross-platform monitoring of users, verification, listings, buyer requirements, matches, quotations, orders, contracts, payment status, quality, disputes, logistics, deliveries, agents, commissions, support, audit logs and reports.

A user must not receive another role's portal merely by changing browser URLs or editing client-side data. Additional roles, if ever needed, require an explicit administrative process and must not merge dashboards.

## 3. Shared experience and navigation

- Desktop: persistent left sidebar, top bar, global search where relevant, notifications and profile controls.
- Mobile: responsive layout and compact bottom navigation for the most-used actions.
- Notifications, Support and Verification are prominent in every applicable participant portal.
- Use a consistent design system while tailoring dashboard content and workflows to each role.
- Visual direction: premium, trustworthy agricultural technology; clean typography, generous spacing, strong real produce photography, clear status timelines, accessible contrast and uncluttered data cards.
- Never display fabricated orders, metrics, ratings, stock, prices or shipment events as real data. Empty states and demo data must be labelled.

## 4. Shared platform capabilities

Build shared services once and expose them through role-appropriate screens:
- Identity, profile, role assignment and verification.
- Produce and commodity catalogue, farm records and batch traceability.
- Buyer requirements, sourcing and supplier matching.
- RFQs, quotations, negotiation, purchase orders and trade contracts.
- Samples, quality inspections, feedback and disputes.
- Inventory, fulfilment, shipment events and delivery confirmation.
- Payment status and auditable financial records; payment processing only after a compliant provider is selected and approved.
- Notifications, support tickets, messaging and document records.
- Market intelligence, seasonal/harvest insights and operational analytics.
- AI-assisted recommendations and summaries, clearly distinguished from verified facts and human approvals.

## 5. Central operating model

DNS administration is the only role with platform-wide visibility. Admins can monitor the full transaction lifecycle and intervene only through authorized, logged actions. Participants see their own records and records shared with them for a transaction. Administrative visibility does not mean unrestricted public access or exposure of private credentials/documents.

## 6. Proposed data domains

The following are logical domains, not a claim that all tables already exist:
- Identity/access: profiles, user roles, role permissions, verification, audit logs.
- Farm operations: farms, locations, crops, production, harvest forecasts.
- Marketplace: produce listings, produce batches, buyer requirements, matches, quotations, orders, order items, contracts.
- Quality/logistics: inspections, produce passports, logistics partners, shipments, shipment events, delivery confirmations, disputes.
- Participant operations: supplier catalogue/inventory, processing facilities/batches, export documents, investment projects, farmland listings, agent assignments/commissions.
- Shared services: notifications, support tickets, messages, document records, platform settings.

**Existing staging findings to validate before migration:** the project has existing buyer/supplier-oriented profile and submission structures, buyer requirements, matching, orders, samples, quality feedback and buyer CRM/follow-up capabilities. Earlier inspection indicated role constraints on `exchange_profiles` and `exchange_submissions` limited to buyer and supplier. Re-query the live schema, constraints, foreign keys, functions, triggers and RLS policies before designing migrations. Do not assume this earlier observation remains unchanged.

## 7. Security and permissions

- Supabase Auth authenticates identity; database-enforced Row Level Security (RLS) authorizes data access.
- Role assignment is validated in trusted server-side/database logic. Users cannot promote themselves or assign admin roles.
- Google sign-in does not equal verification or administrator approval.
- Each role can read/write only its own permitted records and explicitly shared transaction records.
- Admin powers are restricted to approved admin identities and audited.
- Private identity, ownership, export and financial documents belong in private storage with scoped access and signed/authorized retrieval.
- Never expose Supabase service-role keys, Google client secrets or other privileged credentials in browser code, repository files or logs.
- Record important changes to roles, approvals, orders, payments, disputes and admin actions in audit history.

## 8. Technical baseline and operating constraints

- Existing GitHub repository and GitHub Pages frontend.
- Existing DNS Agriculture Exchange Supabase staging project as the integration/test backend, subject to confirming project identity before any write.
- PostgreSQL, Supabase Auth, RLS and private Supabase Storage.
- Preserve working code, existing data and current authentication work.
- Staging first; production only after explicit release approval and successful tests.
- Target additional spend: **₦0**. Do not start trials, enable billing, buy credits or add paid services without explicit approval. Check free-tier limits before selecting integrations.

## 9. Authentication status and known blocker

The login page was updated on GitHub to use the DNS Agriculture Exchange staging project and to improve role/profile bootstrap. GitHub Pages build was reported successful. However, the user's real Google sign-in attempt returned **Error 400: redirect_uri_mismatch**.

The expected Google OAuth authorized redirect URI for the staging Supabase project is:

`https://lvpgasxdmzpsjprohcji.supabase.co/auth/v1/callback`

This URI must be registered under **Authorized redirect URIs** on the exact Google OAuth client whose client ID is configured in Supabase. The correct Google Cloud project/client has not yet been identified from the user's listed projects. Do not claim Google sign-in is fixed until a real browser sign-in succeeds. Regenerate any previously exposed Google client secret before production use.

Password recovery, email registration, profile creation, role routing and each portal's protected access also require end-to-end tests.

## 10. Global product benchmark and design principles

The saved UX research document is the detailed reference for the international benchmark. The product lessons to carry forward are:
- B2B sourcing and market intelligence: strong commodity discovery, supplier discovery and comparable specifications.
- Supply-chain execution: collection, inventory, fulfilment and delivery visibility, not just listings.
- Quality and traceability: verifiable batch origin, inspection records and chain-of-custody events.
- Role-specific operations: each participant gets a focused workspace and workflow.
- Cross-border readiness: export documentation, shipment milestones and currency/market configuration, added only when operationally supportable.

Use these products as research references, not templates to copy. Validate every proposed feature against Nigerian operating realities, user research, cost, compliance and actual delivery capacity.

## 11. Delivery roadmap — one sequence

**Stage 0 — Repository and environment control**
- Keep `main` as canonical.
- Inventory all branches, commits, files and deployment workflows.
- Identify which branch contains the current approved login and registration changes.
- Keep staging and production credentials/configuration separate.

**Stage 1 — Baseline audit**
- Inventory every frontend page, script, shared component and current workflow.
- Inspect the actual Supabase schema, constraints, indexes, foreign keys, triggers, functions, storage buckets and RLS policies.
- Record existing functionality as working, partial, broken or not built.
- Produce a gap register linked to this specification.

**Stage 2 — Identity and access foundation**
- Define canonical role identifiers and profile lifecycle.
- Design a safe migration from existing buyer/supplier constraints to the approved role set.
- Implement and test RLS and admin authorization before exposing new portals.
- Finish Google OAuth and password recovery.

**Stage 3 — Shared design system and navigation**
- Build reusable layout, sidebar, mobile navigation, notifications, support, verification, forms, tables and status components.
- Create approved screen designs for each portal before implementing role workflows.

**Stage 4 — Core marketplace**
- Complete Farmer and Buyer workflows first, then Supplier.
- Verify listings, RFQs, matching, quotations, orders, samples, quality and delivery records end to end.

**Stage 5 — Specialized portals**
- Implement Processor, Exporter, Investor, Farmland Owner and Agent workflows separately.
- Reuse shared services without mixing portal interfaces or permissions.

**Stage 6 — DNS command centre**
- Build cross-platform monitoring, verification queues, transaction/delivery oversight, dispute handling, agent performance, reports and audit views.

**Stage 7 — Intelligence and integrations**
- Add traceability passports, market intelligence, forecasting, logistics integrations and AI assistance incrementally.
- Assess data quality, API availability, costs and privacy before enabling each feature.

**Stage 8 — Release readiness**
- Run role-isolation, RLS, auth, workflow, mobile, accessibility, performance and security tests.
- Verify backup/rollback and deployment behaviour.
- Obtain explicit approval before production release.

## 12. Definition of done

A page loading is not completion. A portal is complete only when:
- Registration/login/recovery works for its role.
- The correct portal loads and persists after refresh.
- Users cannot access another role's private pages or data.
- Database reads/writes obey RLS.
- The key role workflow completes end to end.
- Admin monitoring reflects real transaction states.
- Mobile and desktop layouts work.
- Errors, empty states and audit trails are handled.
- Tests and deployment results are recorded.

## 13. Branch and change-control policy

- `main` is the canonical integration branch.
- Use short-lived, clearly named feature branches for discrete implementation work.
- Before merging: compare commits and changed files against `main`, test the change, and preserve unrelated work.
- Never delete a branch solely because its name looks old or similar. Delete only after its unique commits are merged, superseded or explicitly abandoned and verified.
- Keep one master specification. Supporting documents are references, not competing plans.
- Update this document only when an approved product decision or verified technical fact changes.

## 14. Current verified position at consolidation

- The architecture documentation branch was one commit ahead of `main`; it has now been merged into `main` in merge commit `ba9ef4e72b688ab91be314d8eef024053a195d66`.
- The four supporting documents are present in `main`.
- The authentication branches are not safe to delete based on the available comparison: one has distinct auth work and the other is substantially diverged with multiple application-file changes. They must be reconciled file by file before any branch deletion.
- No database migration or portal rebuild is authorized by this document alone.
- Google OAuth remains blocked by the redirect URI mismatch until the correct OAuth client is configured and a real sign-in test passes.

**This specification is the single project roadmap. Work should advance through the stages above and report each item as not started, in progress, blocked or verified.**
