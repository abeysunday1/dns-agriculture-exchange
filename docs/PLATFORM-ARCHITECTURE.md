# DNS Agriculture Exchange — Platform Architecture

Status: proposed architecture based on repository and staging inspection.
Hosting: GitHub Pages frontend; Supabase staging backend.

## Product direction
Build an end-to-end agricultural commerce and coordination network, not just a produce classifieds site. Connect demand, production, sourcing, processing, quality, documentation, logistics and delivery. Launch Nigeria-first with an export-ready data model. Design for Android phones, low bandwidth and desktop operations.

## Account model
One user selects one primary role at registration and receives one dedicated portal. No role-switching dashboard in the first release.

Roles:
- Farmer: farm profile, crops, harvest forecasts, produce lots, buyer requests, offers, orders and payout status.
- Buyer: sourcing requests, specifications, supplier discovery, quotations, samples, orders, quality feedback and delivery.
- Supplier: agricultural inputs, equipment, packaging and services catalogue, enquiries, quotations and fulfilment.
- Processor: facility profile, raw-material requirements, intake, processing batches, inventory, output lots and quality records.
- Exporter: export enquiries, buyer requirements, supplier aggregation, compliance documents, inspection and shipment milestones.
- Investor: approved opportunities, due diligence packs, milestones and consent-based introductions. No investment custody or guaranteed-return claims in the initial release.
- Farmland owner: land parcels, documents, availability, lease/management enquiries and site visits.
- Agent: assigned onboarding, field visits, verification tasks and collection/delivery updates.
- Administrator: central owner console for all queues, users, verification, orders, delivery, disputes, audit and reporting.

Admin is never a public signup option. Grant it only through a protected owner-controlled process.

## Registration and routing
1. User chooses a role at registration.
2. Auth runs through Supabase Auth (email/password or Google).
3. The registration intent is carried through OAuth, but is not treated as authorization.
4. A server-side function validates the role and creates the profile.
5. User completes role-specific onboarding.
6. New accounts remain pending until required checks are complete.
7. After login, fetch the role from the database and route to that portal. Never trust URL parameters or local storage as the source of permissions.
8. Suspended, pending, missing-profile and unauthorized-admin states get clear status screens.

Proposed paths: /farmer/, /buyer/, /supplier/, /processor/, /exporter/, /investor/, /landowner/, /agent/, /admin/. These may begin as separate HTML entry points with shared auth and reusable UI assets.

## Core platform modules
- Identity, organizations, role profiles and verification.
- Role-specific workspaces, notifications, support and secure documents.
- Product catalogue, farms, crops, produce lots and buyer sourcing requests.
- Matching, quotes, contracts, orders, samples and quality feedback.
- Produce passport with lot origin and append-only custody/handling events.
- Logistics milestones, pickup, dispatch, proof of delivery and exceptions.
- Market intelligence with source, timestamp, unit, geography and freshness.
- Audit events for sensitive changes.

## Trade lifecycle
Buyer submits crop, grade, quantity, unit, packaging, destination and required date. Matching identifies suitable lots and available capacity. Parties exchange structured quotes, agree terms, create an order, arrange samples/inspection where required, then track sourcing, quality, packaging, dispatch and delivery. Buyer records acceptance or discrepancy. Payment is confirmed only by a verified payment event or authorized finance workflow.

## Architecture and security
- Frontend: existing static HTML/CSS/JavaScript hosted on GitHub Pages.
- Auth and database: the DNS Agriculture Exchange Supabase staging project.
- PostgreSQL constraints, foreign keys, indexes and Row Level Security (RLS).
- Private Supabase Storage buckets and signed URLs for documents.
- Privileged actions use database functions or Edge Functions. Never expose service-role keys or OAuth secrets in browser code.
- Admin access is checked server-side and in RLS. Hiding a menu item is not security.
- Validate user, role, organization, payment, verification and state transitions server-side.
- Every business table needs explicit ownership/organization scope and tested RLS.
- Public listings must not reveal exact farm coordinates or private personal data by default.

## Delivery sequence
1. Finish and verify login, profile creation and role routing.
2. Expand role model and secure RLS.
3. Build shared navigation shell and mobile design system.
4. Deliver farmer and buyer workflows using existing tables.
5. Add supplier, processor and exporter workflows.
6. Add landowner, investor and agent workflows.
7. Complete central admin console and audit/reporting.
8. Add traceability, logistics and market intelligence.
9. Run role-based security, accessibility, performance and end-to-end tests.
10. Release only after staging acceptance, backup and rollback planning.

Do not delete or replace existing tables until all dependencies, policies, functions, triggers and data have been inventoried.
