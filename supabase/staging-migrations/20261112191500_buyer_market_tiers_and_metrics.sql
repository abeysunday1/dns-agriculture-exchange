-- Add market-tier segmentation and live target metrics to the buyer acquisition CRM.
alter table public.buyer_prospects
  add column if not exists market_tier text not null default 'tier_4'
  check (market_tier in ('tier_1','tier_2','tier_3','tier_4'));

create or replace function public.classify_buyer_market_tier()
returns trigger language plpgsql set search_path = '' as $$
declare c text;
begin
  c := lower(btrim(coalesce(new.country,'')));
  if c = any(array['united kingdom','uk','great britain','england','united states','usa','us','canada']) then
    new.market_tier := 'tier_1';
  elsif c = any(array['netherlands','germany','france','belgium','italy','spain','sweden','denmark','ireland','austria','poland','portugal']) then
    new.market_tier := 'tier_2';
  elsif c = any(array['united arab emirates','uae','saudi arabia','qatar','kuwait','oman','bahrain','india','china','singapore','malaysia','indonesia','thailand','japan']) then
    new.market_tier := 'tier_3';
  else
    new.market_tier := 'tier_4';
  end if;
  return new;
end;
$$;
drop trigger if exists buyer_prospects_classify_market_tier on public.buyer_prospects;
create trigger buyer_prospects_classify_market_tier
before insert or update of country on public.buyer_prospects
for each row execute function public.classify_buyer_market_tier();

create or replace view public.buyer_acquisition_dashboard
with (security_invoker = true) as
select
  (select count(*) from public.buyer_prospects) as total_prospects,
  (select count(*) from public.buyer_prospects where verification_status = 'verified') as verified_businesses,
  (select count(*) from public.buyer_prospects where stage in ('qualified','specifications_received','quotation_sent','sample_requested','sample_paid','sample_sent','trial_order_negotiation')) as qualified_opportunities,
  (select count(distinct prospect_id) from public.buyer_orders where payment_status = 'paid' and paid_at is not null) as paid_trial_buyers,
  (select count(*) from (select prospect_id from public.buyer_orders where payment_status = 'paid' and paid_at is not null group by prospect_id having count(*) >= 2) repeat_set) as repeat_buyers,
  (select count(*) from public.buyer_prospects where do_not_contact = false and next_follow_up_at <= now()) as follow_ups_due,
  (select count(*) from public.buyer_orders where payment_status = 'paid' and paid_at is not null) as paid_orders,
  (select coalesce(sum(total_value),0) from public.buyer_orders where payment_status = 'paid' and paid_at is not null) as paid_order_value,
  500::integer as paid_trial_buyer_target,
  round(100.0 * (select count(distinct prospect_id) from public.buyer_orders where payment_status = 'paid' and paid_at is not null) / 500.0, 2) as target_progress_percent;

create or replace view public.buyer_acquisition_channel_metrics
with (security_invoker = true) as
select p.source_channel, count(distinct p.id) as prospects,
  count(distinct o.prospect_id) filter (where o.payment_status = 'paid' and o.paid_at is not null) as paid_trial_buyers,
  round(100.0 * count(distinct o.prospect_id) filter (where o.payment_status = 'paid' and o.paid_at is not null) / nullif(count(distinct p.id),0), 2) as trial_conversion_percent
from public.buyer_prospects p left join public.buyer_orders o on o.prospect_id = p.id
group by p.source_channel;

create or replace view public.buyer_acquisition_market_metrics
with (security_invoker = true) as
select p.market_tier, count(distinct p.id) as prospects,
  count(distinct o.prospect_id) filter (where o.payment_status = 'paid' and o.paid_at is not null) as paid_trial_buyers,
  round(100.0 * count(distinct o.prospect_id) filter (where o.payment_status = 'paid' and o.paid_at is not null) / nullif(count(distinct p.id),0), 2) as trial_conversion_percent
from public.buyer_prospects p left join public.buyer_orders o on o.prospect_id = p.id
group by p.market_tier;

grant select on public.buyer_acquisition_dashboard to authenticated;
grant select on public.buyer_acquisition_channel_metrics to authenticated;
grant select on public.buyer_acquisition_market_metrics to authenticated;
