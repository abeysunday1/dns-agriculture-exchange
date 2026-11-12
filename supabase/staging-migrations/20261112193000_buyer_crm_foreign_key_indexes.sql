-- Cover buyer CRM foreign keys to keep joins and deletes efficient as the pipeline grows.
create index if not exists buyer_prospects_created_by_idx on public.buyer_prospects(created_by);
create index if not exists buyer_interactions_created_by_idx on public.buyer_interactions(created_by);
create index if not exists buyer_opportunities_created_by_idx on public.buyer_opportunities(created_by);
create index if not exists buyer_samples_created_by_idx on public.buyer_samples(created_by);
create index if not exists buyer_orders_created_by_idx on public.buyer_orders(created_by);
create index if not exists buyer_orders_opportunity_fk_idx on public.buyer_orders(opportunity_id) where opportunity_id is not null;
create index if not exists buyer_supply_matches_created_by_idx on public.buyer_supply_matches(created_by);
create index if not exists buyer_supply_matches_submission_idx on public.buyer_supply_matches(supplier_submission_id);
create index if not exists buyer_quality_feedback_created_by_idx on public.buyer_quality_feedback(created_by);
create index if not exists buyer_quality_feedback_submission_idx on public.buyer_quality_feedback(supplier_submission_id) where supplier_submission_id is not null;
