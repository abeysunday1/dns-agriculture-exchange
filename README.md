# DNS Agriculture Exchange

Mobile-first farmer/supplier portal prototype for DigitalNewsSpace Agriculture Exchange.

## Preview
This is a static UI prototype. It uses illustrative sample data only.

## Important limitations
- No Supabase connection, authentication, database writes, file uploads, email delivery or support ticket storage.
- No real supplier or stock verification.
- No real buyer identities or transactions.
- Buyer privacy rules are represented in the interface but still require server-side enforcement and Supabase Row Level Security before production.

## Local preview
Open index.html in a browser.

## Next implementation stages
1. Review existing Supabase project and CRM schema/RLS without changing it.
2. Design separate agriculture tables and least-privilege policies.
3. Connect authentication and supplier onboarding.
4. Add buyer portal, admin operations and customer care.
5. Deploy production build only after security review.
