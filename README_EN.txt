KoOo Mini POS Cloud 3.0

This is a source package that becomes connected after you create a Supabase project and configure js/config.js. It is not pre-connected to a cloud account.

Setup
1. Create a free project at https://supabase.com.
2. Copy the Project URL and Publishable key (or legacy anon public key) from Project Settings / API Keys.
3. Run the complete sql/schema.sql in Supabase SQL Editor.
4. Edit js/config.js and replace the two placeholders.
5. Host this folder on HTTPS or localhost. Direct file:// opening does not support service workers/PWA installation.
6. Open the hosted URL, create an account, enter a store name, confirm email if required, then sign in.
7. Open the same HTTPS URL on another device and sign in to the same account.

Never place a service_role or secret key in browser code. RLS is essential.

Offline behavior
- App shell is cached by the service worker after first online load.
- Checkout actions are stored in IndexedDB and queued for retry when connectivity returns.
- Do not clear browser/site data while offline items are pending. The outbox is device-local and is not replicated to other devices until synced.
- Product/customer/expense changes use optimistic local cache and queued upserts. This starter has limited conflict handling and is not safe for simultaneous offline edits by multiple users.

Current scope/limitations
- Multi-device sync for the same signed-in user/store, products, customers, sales, expenses.
- Atomic server-side sale posting and stock deduction; the database calculates prices/cost from product records and sale UUID makes retries idempotent.
- Basic roles are stored; browser-based team invitations are not enabled.
- No supplier/purchase management, returns/refunds, complete staff permission UI, full conflict resolution, or scheduled backup automation yet.
- Supabase free-tier limits, pausing and retention can change; check your project dashboard.
- Test thoroughly before real business use and maintain separate backups.
