# Buyer acquisition CRM (staging)

This module extends the existing DNS Agriculture Exchange admin console. It is not a separate business model or standalone spreadsheet.

## Data flow

- `buyer_prospects`: business identity, buyer segment, market, source channel, products, contact basis, owner, pipeline stage, and next follow-up.
- `buyer_interactions`: dated record of research, outbound contact, inbound response, calls, meetings, quotations, samples, and feedback.
- `buyer_opportunities`: exact product, grade, quantity, destination, packaging, documentation, target date, quotation, and estimated cost.
- `buyer_samples`: paid sample status, sample and courier costs, dispatch tracking, and buyer feedback.
- `buyer_orders`: trial and repeat orders, payment, quality, fulfillment, logistics, and delivery.
- `buyer_supply_matches`: links a buyer requirement to a real supplier submission in `exchange_submissions`.
- `buyer_quality_feedback`: links buyer feedback to an order and, where available, the supplying farmer submission.

## Trial-buyer definition

A prospect counts toward the 300–500 paid trial-buyer target only when at least one real order has payment status `paid` and a verified `paid_at` timestamp. The database trigger automatically assigns `paid_trial_buyer` after the first paid order and `repeat_buyer` after the second. The database rejects those stages when the corresponding paid-order evidence does not exist.

## Security and scope

- The CRM tables have Row Level Security enabled.
- Only authenticated users recognized by `public.is_exchange_admin()` can access these tables.
- Contact permission / lawful basis and do-not-contact status are recorded on every prospect. The UI blocks outbound interaction logging if contact is not allowed.
- The page `buyer-crm.html` is hard-wired to the isolated staging Supabase project. Do not publish or merge it into production without a deliberate production configuration change and release review.
- No live production tables, main branch, existing production-connected Activepieces flow, or production website were changed by this work.

## Current limitations

The page currently supports prospect capture, pipeline stages, contact-history logging, buyer requirement capture, paid trial-order recording, and dashboard counts. It does not automatically send emails, WhatsApp messages, or scrape contact data. Outreach automation must be connected only after a staging-safe integration is configured, and must respect the prospect's contact basis and opt-out status.
