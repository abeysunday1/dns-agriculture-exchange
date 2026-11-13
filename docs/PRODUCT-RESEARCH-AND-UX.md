# DNS Agriculture Exchange — Global Product Research & UX Direction

Research date: 13 November 2026. This is a public-source benchmark, not a copy of competitors' brands or proprietary interfaces.

## 1. Products studied and lessons

### Tridge — global B2B agri-food trade and market intelligence
https://www.tridge.com/
Observed: product-first discovery, buyer demand and seller supply as separate market signals, verified companies, live deals, sourcing requests, product catalogues, country/product intelligence and source-backed AI briefs.
DNS adaptation: buyers start with a structured sourcing need; farmers/exporters see relevant demand; market statistics always show source, timestamp, unit and geography; matching explains product, grade, volume, location and availability fit.

### Ninjacart — operational supply chain
https://ninjacart.com/
Observed: addresses produce movement end-to-end; quality, payment risk, distribution and timely information are core operations; multiple value-chain participants have distinct workflows; technology supports demand and route planning.
DNS adaptation: one order timeline from sourcing to delivery; quality and custody events; aggregation when one farmer cannot meet a buyer's volume; mobile field updates.

### Thrum — farmer app plus role-based ERP
https://thrummel.com/
Observed: separate experiences for farmers, buyers, field agents and operations/finance; farmer flows use simple register/grow/sell/get-paid steps; backoffice combines farmer, inventory, trade, logistics and reporting.
DNS adaptation: dedicated portals are appropriate; keep farmer screens task-led; give the owner a central control tower; make agent assignments and field verification first-class workflows.

### FAO Digital Services Portfolio
https://www.fao.org/digital-services/country-cases/en
Observed: marketplaces can coexist with crop calendars, advisory and community knowledge; localization and regional production context matter.
DNS adaptation: low-bandwidth screens, plain language, localized crop calendars later, Nigerian state/LGA/community location fields.

### World Bank — West African digital agriculture
https://www.worldbank.org/en/results/2025/03/04/afw-from-fields-to-markets-the-role-of-digital-platforms-in-west-african-agricultural-success
Observed: digital platforms improve market access and timely information; digital financial inclusion and rural connectivity are enabling conditions.
DNS adaptation: design for low bandwidth; make buyer demand visible; do not assume every farmer has a bank app, constant data or formal business registration.

### FAO traceability study
https://www.fao.org/family-farming/detail/en/c/1651890/
Observed: traceability can improve origin, quality and food-safety transparency; weak logistics and cold chain contribute to losses; reliable traceability needs consistent data and event history.
DNS adaptation: build lot records and handling events before QR labels; capture grading, inspection, storage, dispatch and receipt; show missing evidence rather than awarding false verification.

## 2. DNS opportunity
The differentiation is to connect demand, production, transformation and delivery in one accountable operating system:
1. Demand-to-farm matching from buyer specifications.
2. Volume aggregation while preserving each source lot's traceability.
3. One shipment timeline for milestones, evidence, documents and delivery.
4. Dedicated workspaces for every role.
5. Owner control tower for queues, exceptions, verification, orders and service quality.
6. Explainable matching rather than mysterious AI scores.
7. Local-first data with Nigerian locations, metric units, NGN and multi-currency support.
8. Trust by evidence: verification badges only after actual review.

## 3. Original design system
Character: professional B2B operations software—clean, calm, trustworthy and practical. Not a social feed or flashy crypto dashboard.

Visual language:
- Primary agricultural green for core actions and positive states.
- Warm white/light grey surfaces and dark slate text.
- Restrained amber for attention and review states.
- Red only for errors, blocked actions and critical exceptions.
- Clear typography, consistent status chips, comfortable spacing and high-contrast controls.
- Real crop/product images only when they aid identification; avoid decorative stock-photo overload.

Layout:
- Desktop: collapsible left sidebar; top bar with search, notifications and account menu; clear page title and one primary action; summary cards then work queue/table.
- Mobile: compact header, bottom navigation for the most-used destinations, full-screen forms, large tap targets and progress steps.
- Convert dense tables to cards on narrow screens.
- Forms are short, save progress, show units and validate inline.
- Empty states explain the next action.

Reusable components: portal shell, role badge, KPI card, work queue, search/filter, product/lot card, buyer requirement card, quote comparison, order timeline, verification checklist, secure document uploader, notification centre, support panel and admin audit timeline.

## 4. Screens to design before implementation
1. Role selection and registration.
2. First-login onboarding for each role.
3. Role-specific dashboard.
4. Buyer sourcing request.
5. Farmer produce-lot creation.
6. Supplier catalogue and quotation.
7. Processor intake and batch management.
8. Exporter compliance and shipment workspace.
9. Investor opportunity review.
10. Land parcel and enquiry.
11. Agent assignment and field visit.
12. Admin control tower and verification queue.
13. Order detail with shared lifecycle timeline.
14. Produce lot passport and traceability history.

## 5. UX rules
- Never show every role the same dashboard with only labels changed.
- Do not place unrelated modules in a portal sidebar.
- One dominant next action per screen.
- Display currency and units beside every amount/quantity.
- Distinguish estimated, quoted, confirmed and paid.
- Show source and last-updated time for market data.
- Keep exact farm coordinates private by default.
- Never claim identity, product, payment, certificate or delivery is verified without evidence.
- Keep status language consistent across portals.
- Notifications link to the relevant record.
- Support keyboard access, visible focus, accessible labels and useful loading/empty/error/offline states.

## 6. Research limitations
This first benchmark uses public product pages and institutional case studies. It is not a full usability audit or access to private competitor dashboards. Before final visual approval, inspect live product flows and conduct task-based tests with Nigerian farmers, buyers and field agents. The DNS design must remain original.

## Sources
- Tridge: https://www.tridge.com/
- Tridge overview: https://www.tridge.com/about/company-introduction
- Ninjacart: https://ninjacart.com/
- Thrum: https://thrummel.com/
- FAO country cases: https://www.fao.org/digital-services/country-cases/en
- World Bank West Africa: https://www.worldbank.org/en/results/2025/03/04/afw-from-fields-to-markets-the-role-of-digital-platforms-in-west-african-agricultural-success
- FAO traceability: https://www.fao.org/family-farming/detail/en/c/1651890/
- FAO AgriTech Observatory: https://agritechobservatory.review.fao.org/en/connected-farmers
