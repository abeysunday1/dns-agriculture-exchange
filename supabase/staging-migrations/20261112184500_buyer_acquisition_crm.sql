-- STAGING-FIRST buyer acquisition CRM for DNS Agriculture Exchange.
-- Applied only to the isolated staging project; never apply to production without release approval.
create table if not exists public.buyer_prospects (
  id uuid primary key default gen_random_uuid(),
  business_name text not null check (char_length(btrim(business_name)) between 2 and 180),
  buyer_type text not null default 'other' check (buyer_type in ('diaspora_retailer','importer','distributor','processor','manufacturer','wholesaler','institutional','local_commercial','other')),
  country text, city text, website text, contact_name text, contact_role text, email text, phone text,
  source_channel text not null default 'other' check (source_channel in ('google_maps','google_search','linkedin','whatsapp','telegram','facebook','instagram','email','trade_platform','referral','event','website','other')),
  source_url text, product_interests text[] not null default '{}',
  verification_status text not null default 'unverified' check (verification_status in ('unverified','pending','verified','rejected')),
  stage text not null default 'new' check (stage in ('new','business_verified','contact_identified','contacted','responded','qualified','specifications_received','quotation_sent','sample_requested','sample_paid','sample_sent','trial_order_negotiation','paid_trial_buyer','repeat_buyer','lost','disqualified')),
  contact_allowed boolean not null default false, contact_basis text, do_not_contact boolean not null default false,
  assigned_to text not null default 'Unassigned', notes text, last_contacted_at timestamptz, next_follow_up_at timestamptz,
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index if not exists buyer_prospects_email_unique on public.buyer_prospects (lower(email)) where email is not null and btrim(email) <> '';
create index if not exists buyer_prospects_followup_idx on public.buyer_prospects (next_follow_up_at) where do_not_contact = false;
create index if not exists buyer_prospects_stage_idx on public.buyer_prospects(stage);
create index if not exists buyer_prospects_country_idx on public.buyer_prospects(country);

create table if not exists public.buyer_interactions (
  id uuid primary key default gen_random_uuid(), prospect_id uuid not null references public.buyer_prospects(id) on delete cascade,
  channel text not null check (channel in ('linkedin','email','whatsapp','telegram','facebook','instagram','phone','meeting','trade_platform','other')),
  direction text not null default 'outbound' check (direction in ('inbound','outbound','internal')),
  activity_type text not null default 'message' check (activity_type in ('research','first_contact','follow_up','call','meeting','quotation','sample_update','order_update','feedback','other')),
  summary text not null check (char_length(btrim(summary)) between 2 and 3000), outcome text,
  occurred_at timestamptz not null default now(), next_follow_up_at timestamptz,
  created_by uuid not null default auth.uid() references auth.users(id), created_at timestamptz not null default now()
);
create index if not exists buyer_interactions_prospect_idx on public.buyer_interactions(prospect_id, occurred_at desc);

create table if not exists public.buyer_opportunities (
  id uuid primary key default gen_random_uuid(), prospect_id uuid not null references public.buyer_prospects(id) on delete cascade,
  product_name text not null check (char_length(btrim(product_name)) between 2 and 120), grade_specification text,
  required_quantity numeric(14,3) not null check (required_quantity > 0),
  quantity_unit text not null default 'kg' check (quantity_unit in ('kg','tonne','litre','piece','carton','other')),
  destination text, packaging_requirement text, required_documents text[] not null default '{}',
  target_delivery_date date, status text not null default 'open' check (status in ('open','qualified','specifications_confirmed','quoted','sample_stage','negotiation','won','lost','on_hold')),
  currency char(3) not null default 'USD', quoted_unit_price numeric(14,2) check (quoted_unit_price is null or quoted_unit_price >= 0),
  quoted_total numeric(14,2) check (quoted_total is null or quoted_total >= 0),
  estimated_total_cost numeric(14,2) check (estimated_total_cost is null or estimated_total_cost >= 0),
  lost_reason text, notes text, created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists buyer_opportunities_prospect_idx on public.buyer_opportunities(prospect_id);
create index if not exists buyer_opportunities_status_idx on public.buyer_opportunities(status);

create table if not exists public.buyer_samples (
  id uuid primary key default gen_random_uuid(), opportunity_id uuid not null references public.buyer_opportunities(id) on delete cascade,
  quantity numeric(12,3) not null check (quantity > 0), quantity_unit text not null default 'kg',
  sample_cost numeric(14,2) not null default 0 check (sample_cost >= 0), courier_cost numeric(14,2) not null default 0 check (courier_cost >= 0),
  currency char(3) not null default 'USD', status text not null default 'requested' check (status in ('requested','quoted','paid','dispatched','delivered','feedback_received','cancelled')),
  tracking_reference text, dispatched_at timestamptz, delivered_at timestamptz, buyer_feedback text, notes text,
  created_by uuid not null default auth.uid() references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists buyer_samples_opportunity_idx on public.buyer_samples(opportunity_id);

create table if not exists public.buyer_orders (
  id uuid primary key default gen_random_uuid(), order_number text not null unique,
  prospect_id uuid not null references public.buyer_prospects(id), opportunity_id uuid references public.buyer_opportunities(id),
  product_name text not null, grade_specification text, quantity numeric(14,3) not null check (quantity > 0),
  quantity_unit text not null default 'kg', currency char(3) not null default 'USD',
  unit_price numeric(14,2) not null check (unit_price >= 0), total_value numeric(14,2) not null check (total_value >= 0),
  payment_status text not null default 'pending' check (payment_status in ('pending','partial','paid','refunded','failed')),
  paid_at timestamptz, quality_status text not null default 'not_inspected' check (quality_status in ('not_inspected','pending','accepted','conditional','rejected')),
  fulfillment_status text not null default 'not_started' check (fulfillment_status in ('not_started','sourcing','inspection','packaging','dispatched','delivered','cancelled')),
  logistics_partner text, shipment_reference text, delivery_due_at timestamptz, delivered_at timestamptz, notes text,
  created_by uuid not null default auth.uid() references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check ((payment_status <> 'paid') or paid_at is not null)
);
create index if not exists buyer_orders_prospect_idx on public.buyer_orders(prospect_id, created_at);
create index if not exists buyer_orders_paid_idx on public.buyer_orders(paid_at) where payment_status = 'paid';

create table if not exists public.buyer_supply_matches (
  id uuid primary key default gen_random_uuid(), opportunity_id uuid not null references public.buyer_opportunities(id) on delete cascade,
  supplier_submission_id uuid not null references public.exchange_submissions(id),
  proposed_quantity numeric(14,3) check (proposed_quantity is null or proposed_quantity >= 0),
  accepted_quantity numeric(14,3) check (accepted_quantity is null or accepted_quantity >= 0),
  inspection_status text not null default 'pending' check (inspection_status in ('pending','accepted','conditional','rejected')),
  notes text, created_by uuid not null default auth.uid() references auth.users(id), created_at timestamptz not null default now(),
  unique(opportunity_id, supplier_submission_id)
);

create table if not exists public.buyer_quality_feedback (
  id uuid primary key default gen_random_uuid(), order_id uuid not null references public.buyer_orders(id) on delete cascade,
  supplier_submission_id uuid references public.exchange_submissions(id),
  grade_outcome text not null check (grade_outcome in ('accepted','conditional','rejected')),
  quality_metrics jsonb not null default '{}'::jsonb, buyer_feedback text, corrective_action text,
  received_at timestamptz not null default now(), created_by uuid not null default auth.uid() references auth.users(id), created_at timestamptz not null default now()
);
create index if not exists buyer_quality_feedback_order_idx on public.buyer_quality_feedback(order_id);

create or replace function public.touch_buyer_crm_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists buyer_prospects_touch_updated_at on public.buyer_prospects;
create trigger buyer_prospects_touch_updated_at before update on public.buyer_prospects for each row execute function public.touch_buyer_crm_updated_at();
drop trigger if exists buyer_opportunities_touch_updated_at on public.buyer_opportunities;
create trigger buyer_opportunities_touch_updated_at before update on public.buyer_opportunities for each row execute function public.touch_buyer_crm_updated_at();
drop trigger if exists buyer_samples_touch_updated_at on public.buyer_samples;
create trigger buyer_samples_touch_updated_at before update on public.buyer_samples for each row execute function public.touch_buyer_crm_updated_at();
drop trigger if exists buyer_orders_touch_updated_at on public.buyer_orders;
create trigger buyer_orders_touch_updated_at before update on public.buyer_orders for each row execute function public.touch_buyer_crm_updated_at();

alter table public.buyer_prospects enable row level security;
alter table public.buyer_interactions enable row level security;
alter table public.buyer_opportunities enable row level security;
alter table public.buyer_samples enable row level security;
alter table public.buyer_orders enable row level security;
alter table public.buyer_supply_matches enable row level security;
alter table public.buyer_quality_feedback enable row level security;

do $$
declare t text;
begin
  foreach t in array array['buyer_prospects','buyer_interactions','buyer_opportunities','buyer_samples','buyer_orders','buyer_supply_matches','buyer_quality_feedback']
  loop
    execute format('drop policy if exists %I on public.%I', t || '_admin_all', t);
    execute format('create policy %I on public.%I for all to authenticated using (public.is_exchange_admin()) with check (public.is_exchange_admin())', t || '_admin_all', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

comment on table public.buyer_prospects is 'Verified commercial buyer CRM. A paid trial buyer is counted only after a first order is recorded as paid.';
comment on table public.buyer_interactions is 'Auditable buyer contact, follow-up, meeting, quotation, and feedback history.';
comment on table public.buyer_opportunities is 'Buyer-specific product requirements, grades, quantities, destination, documents, and quotations.';
comment on table public.buyer_samples is 'Paid sample and courier tracking. Free samples must not be assumed.';
comment on table public.buyer_orders is 'Commercial trial and repeat orders; paid_at is required before payment_status can be paid.';
comment on table public.buyer_supply_matches is 'Links buyer requirements to actual supplier submissions for aggregation and quality matching.';
comment on table public.buyer_quality_feedback is 'Buyer quality feedback linked back to orders and, where possible, supplier submissions.';
