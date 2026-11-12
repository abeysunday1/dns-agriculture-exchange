-- Remove broad default grants on buyer CRM tables/views.
-- RLS remains the row-level gate; table privileges must also exclude TRUNCATE and anonymous access.
revoke all privileges on table
  public.buyer_prospects,
  public.buyer_interactions,
  public.buyer_opportunities,
  public.buyer_samples,
  public.buyer_orders,
  public.buyer_supply_matches,
  public.buyer_quality_feedback
from anon, authenticated, public;

grant select, insert, update, delete on table
  public.buyer_prospects,
  public.buyer_interactions,
  public.buyer_opportunities,
  public.buyer_samples,
  public.buyer_orders,
  public.buyer_supply_matches,
  public.buyer_quality_feedback
to authenticated;

revoke all privileges on table
  public.buyer_acquisition_dashboard,
  public.buyer_acquisition_channel_metrics,
  public.buyer_acquisition_market_metrics
from anon, authenticated, public;

grant select on table
  public.buyer_acquisition_dashboard,
  public.buyer_acquisition_channel_metrics,
  public.buyer_acquisition_market_metrics
to authenticated;
