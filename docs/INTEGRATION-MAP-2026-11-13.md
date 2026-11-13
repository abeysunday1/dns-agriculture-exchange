# DNS Agriculture Exchange — Integration Map

Date: 13 November 2026
Branch: staging/dns-exchange-audit-2026-11-13

## Goal
Connect the platform through a single server-side integration layer. The web client talks only to the DNS staging backend. The backend calls providers through Edge Functions or trusted server services. Provider secrets must be stored in server-side secrets, never in browser JavaScript or public GitHub files.

## Current connection status

| Service | Current status | Intended app use | Remaining work |
|---|---|---|---|
| GitHub | Connected | Source control and staging deployment | Keep staging isolated; configure CI checks |
| Supabase DNS staging | Connected; healthy | Auth, PostgreSQL, RLS, Edge Functions, realtime | Reconcile all frontend references; later auth and policy work |
| Google Maps | Connected at assistant integration layer | Address lookup, geocoding, distance, routes and delivery locations | Verify DNS-owned Google Cloud project, API restrictions, billing and app key before embedding |
| Gmail | Connected at assistant integration layer | Staff mailbox and operational communication | Not a transactional app email service; do not use personal mailbox credentials in browser |
| Google Drive | Connected at assistant integration layer | Staff documents and internal files | Decide whether app files belong in private Supabase Storage instead |
| Paystack | Authorization initiated; pending user completion | Buyer checkout, transaction verification, refunds/reconciliation where supported | Complete connection; then configure server-side test keys and signed webhook endpoint |
| WhatsApp Business | Authorization initiated; pending user completion | OTP/templates where supported, order updates, support notifications | Complete Meta authorization; select WABA and phone number; verify templates and opt-in |
| Resend | Authorization initiated; pending user completion | Transactional verification, receipts and order emails | Complete connection; verify DNS sending domain and sender identity |
| Logistics provider | Not selected/connected | Dispatch assignment, tracking, delivery proof | Choose a provider operating in Nigeria; agree API, pricing and service coverage |
| SMS provider | Not selected/connected | Fallback OTP and urgent delivery alerts | Decide whether needed after WhatsApp/email; select local coverage and cost |

## Integration architecture

1. DNS web portals (all participant roles) use one Supabase staging project.
2. Supabase Auth identifies users; database roles and RLS enforce access.
3. Edge Functions/server-side services orchestrate provider calls.
4. Paystack handles payment initiation and verification. A signed webhook plus server-side verification updates the internal ledger idempotently. Farmer settlement happens only under the agreed contract and after cleared funds/acceptance conditions.
5. Google Maps handles geocoding, route and distance services; location data is limited to what each role needs.
6. Resend handles transactional email; WhatsApp Business handles consented template/utility updates.
7. A selected logistics partner receives only the delivery data required for assigned jobs and returns tracking events.
8. Supabase private Storage holds verification documents, commodity inspection files and delivery evidence with scoped policies.
9. Central audit events record provider requests, webhook outcomes, retries and failures without storing secrets or full payment credentials.

## Connection boundary

A connected provider in the ChatGPT/Composio workspace does not automatically connect that provider to the DNS application. App integration requires DNS-owned credentials, configured server-side secrets, endpoint/webhook setup, least-privilege scopes, and end-to-end staging tests. Do not copy provider secrets into frontend code, GitHub commits, SQL migrations or chat messages.

## Work order after provider authorization

1. Confirm active Paystack, WhatsApp and Resend connections.
2. Verify DNS-owned provider accounts, environment (test vs live), sender domains, WABA/phone number, and API permissions.
3. Select and verify a Nigeria-capable logistics provider.
4. Configure server-side secrets and webhook endpoints in staging.
5. Run provider sandbox tests and failure/retry tests.
6. Once the integration layer is verified, begin authentication and production-readiness repairs in staging. Do not merge or deploy to production until explicitly approved and tested.
