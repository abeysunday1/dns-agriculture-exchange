# Buyer acquisition CRM (staging)

This module extends the existing DNS Agriculture Exchange admin console. It is not a separate business model or standalone spreadsheet.

## Data flow

- `buyer_prospects`: business identity, buyer category, market, source channel, product interests, contact basis, assigned owner, pipeline stage, and next follow-up.
- `buyer_interactions`: dated record of research, outbound contact, inbound response, calls, meetings, quotations, samples, and feedback.
- `buyer_opportunities`: exact product, grade, quantity, destination, packaging, documentation, target date, quotation, and estimated cost.
- `buyer_samples`: paid sample status, sample and courier costs, dispatch tracking, and buyer feedback.
- `buyer_orders`: trial and repeat orders, payment, quality, fulfillment, logistics, and delivery.
- `buyer_supply_matches`: links a buyer requirement to a real supplier submission in `exchange_submissions`.
- `buyer_quality_feedback`: links buyer feedback to an order and, where available, the supplying farmer submission.

## 300–500 buyer measurement

A prospect counts toward the paid trial-buyer target only when at least one real order has payment status `paid` and a recorded `paid_at` timestamp. The database automatically assigns `paid_trial_buyer` after the first paid order and `repeat_buyer` after the second. The database rejects those stages when corresponding paid-order evidence does not exist.

The `market_tier` field is assigned from the buyer country:
- Tier 1: UK, USA, Canada.
- Tier 2: Netherlands, Germany, France, Belgium, Italy, and selected European markets.
- Tier 3: UAE, Saudi Arabia, Qatar, India, China, and selected Asian markets.
- Tier 4: Nigeria, other African markets, and other countries.

Reporting views:
- `buyer_acquisition_dashboard`: total prospects, verified businesses, qualified opportunities, paid trial buyers, repeat buyers, overdue follow-ups, paid orders, paid order value, and progress against the 500-buyer target.
- `buyer_acquisition_channel_metrics`: prospects, paid trial buyers, and conversion by acquisition channel.
- `buyer_acquisition_market_metrics`: prospects, paid trial buyers, and conversion by market tier.

## Security and scope

- All seven CRM tables have Row Level Security enabled.
- Only authenticated users recognized by `public.is_exchange_admin()` can access CRM records.
- Anonymous privileges are revoked. Authenticated access is limited to SELECT, INSERT, UPDATE, and DELETE; TRUNCATE is not granted.
- Contact permission / lawful basis and do-not-contact status are recorded on each prospect. The UI blocks outbound interaction logging if contact is not allowed.
- The page `buyer-crm.html` is hard-wired to the isolated staging Supabase project. Do not publish or merge it into production without a deliberate production configuration change and release review.
- No production tables, `main` branch, production website, or existing production-connected Activepieces flow were changed.

## Current limitations

The current page supports prospect capture, pipeline stages, contact-history logging, buyer requirement capture, paid trial-order recording, and basic dashboard counts. The database already supports sample tracking, supply matching, quality feedback, and channel/market reporting, but those workflows still need their admin screens. It does not automatically send emails, WhatsApp messages, or scrape contact data. Outreach automation must be connected only after a staging-safe integration is configured and must respect contact basis and opt-out status.
