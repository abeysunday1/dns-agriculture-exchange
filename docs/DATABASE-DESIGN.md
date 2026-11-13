# DNS Agriculture Exchange — Proposed Database Design

This is a target design, not a migration script. Reconcile it with live staging tables, foreign keys, functions, triggers, indexes, grants and RLS policies before running SQL.

## 1. Current staging baseline
Inspected tables include:
- exchange_profiles: one profile per auth user; account_type currently permits only buyer or supplier; account_status permits pending, active or suspended.
- exchange_submissions and exchange_automation_events.
- buyer_prospects, buyer_interactions, buyer_opportunities, buyer_samples, buyer_orders, buyer_supply_matches and buyer_quality_feedback.
- account_deletion_requests.

RLS is enabled on the inspected tables. Existing buyer sourcing, samples, orders, matching and quality feedback structures should be reused where possible.

## 2. Identity and organization
### exchange_profiles (evolve, do not replace)
Retain user_id as auth.users primary/foreign key. Expand account_type to farmer, buyer, supplier, processor, exporter, investor, landowner and agent. Do not allow admin as a public role.
Add as needed: organization_id, display_name, phone_verified_at, onboarding_completed_at, verification_status, preferred_language, timezone, last_active_at. Keep account lifecycle separate from verification.

### organizations
id, legal_name, display_name, registration_country, registration_number (restricted), business_type, website, contact_email, contact_phone, verification_status, timestamps.

### organization_members
organization_id, user_id, membership_role, status, created_at. Enables team accounts later without changing each user's primary portal.

### platform_admins
user_id, admin_level, granted_by, granted_at, revoked_at. Writes restricted to trusted owner/server process; no client insert/update.

## 3. Farms and produce
### farms
id, owner_user_id, organization_id, farm_name, country, state, lga, community, private coordinates, farm_size, size_unit, production_methods, verification_status, timestamps. Exact coordinates remain private by default.

### farm_crops
id, farm_id, crop_code, crop_name, variety, season, area_planted, area_unit, expected_harvest_date, estimated_yield, yield_unit, status.

### produce_lots
id, farmer_user_id, farm_id, crop_name, variety, grade, quantity_available, quantity_unit, harvest_date, available_from, price_type, asking_price, currency, packaging, storage_conditions, public_location, lot_status, verification_status, timestamps.

### lot_events
Append-only event history: id, lot_id, event_type, occurred_at, actor_user_id, location_reference, quantity, unit, notes, evidence_document_id, created_at. Event types include harvest, aggregation, inspection, grading, packing, storage, dispatch, receipt and transformation.

## 4. Trade domain
Reuse and carefully extend buyer_opportunities, buyer_supply_matches, buyer_orders, buyer_samples and buyer_quality_feedback.
Add:
- quotes and quote_items: parties, requested lot/product, quantity, unit, unit price, currency, validity, terms and status.
- trade_contracts: parties, accepted quote, contract reference, terms version, status, signed-document reference.
- order_events: append-only lifecycle history with actor, state transition, timestamp and evidence.
- disputes: order, raised_by, category, description, evidence, status, resolution and reviewer.
- payment_records: external provider reference, amount, currency, status, verified timestamp and source. Never store card PAN, CVV, bank passwords or online banking credentials. Client-reported payment is not confirmed payment.

## 5. Role-specific tables
- Supplier: supplier_catalogue_items, supplier_inventory, supplier_quotes.
- Processor: processing_facilities, processing_capacity, processing_intake_slots, processing_batches, batch_inputs, batch_outputs, quality_checks.
- Exporter: export_profiles, export_market_requirements, export_document_requirements, export_shipments, shipment_milestones.
- Investor: investment_opportunities, opportunity_documents, investor_interests, due_diligence_access with strict consent and visibility.
- Landowner: land_parcels, land_documents, land_availability, land_enquiries, site_visits, land_offers.
- Agent: agent_assignments, field_visits, onboarding_tasks, agent_activity_logs.
- Verification: verification_cases, verification_documents, verification_reviews.

## 6. Shared operations
notifications; support_tickets; support_messages; file_documents; audit_events; saved_items; conversations; messages; market_observations. Every record must have explicit owner, organization or access scope. Market observations need source, timestamp, geography, unit and freshness.

## 7. Relationships
auth.users 1:1 exchange_profiles.
organizations 1:many organization_members.
farms 1:many farm_crops and produce_lots.
produce_lots 1:many lot_events.
buyer_opportunities 1:many buyer_supply_matches, quotes and samples.
quotes 1:many quote_items; accepted quote may create a trade_contract and buyer_order.
buyer_orders 1:many order_events, payment_records, quality feedback and disputes.
agent_assignments define the scope of agent access.

## 8. Migration sequence
1. Inventory all staging tables, views, functions, triggers, enums, indexes, grants and RLS policies.
2. Identify reusable structures and migration conflicts.
3. Add role values and organization/admin membership structures in staging.
4. Update profile bootstrap function to validate roles server-side.
5. Add and test RLS before exposing new portals.
6. Add domain tables in small migrations with constraints, indexes and policies.
7. Use clearly labeled non-sensitive demo data only.
8. Test each role with separate accounts.
9. Record rollback SQL and migration versions.

Never expose Supabase service-role keys or OAuth client secrets in frontend files or GitHub. No destructive production migration is authorized by this document.
