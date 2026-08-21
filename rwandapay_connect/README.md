# RwandaPay Connect

A simulated cross-border remittance demo: money is sent from the United States
to Rwanda, converted USD → RWF, and cashed out to MTN MoMo. Flutter web
frontend, Supabase (Postgres) backend.

No real payment processor, bank API, or MTN MoMo API is involved. All "money"
lives in this project's own database.

## Setup

### 1. Create the database

Open the SQL Editor for the Supabase project:

    https://supabase.com/dashboard/project/dohwtewodbheczloukyh/sql/new

Paste the entire contents of [`supabase/schema.sql`](supabase/schema.sql) and
click **Run**. This creates the tables, the money-movement functions, and the
four demo accounts.

The script drops and recreates everything, so running it again resets the demo
to its starting state — useful for rehearsing the presentation.

### 2. Verify it worked

    ./supabase/verify.sh

Every line should be a green ✓. If not, the script says what to fix.

### 3. Run the app

    flutter run -d chrome

## Demo accounts

| Role | Email | Password | Starting balance |
|------|-------|----------|------------------|
| Sender | james.whitmore@demo-rwandapay.com | `Sender@2026` | $500.00 USD |
| Receiver 1 | uwase.aline@demo-rwandapay.com | `Receiver1@2026` | 0 RWF |
| Receiver 2 | niyonzima.eric@demo-rwandapay.com | `Receiver2@2026` | 0 RWF |
| Admin | admin@demo-rwandapay.com | `Admin@2026` | — |

## Switching between roles

There is no role switcher. Each account is a separate login, so you change
role by signing out and signing back in as someone else:

1. Tap **Exit** in the bottom nav (or **Sign Out** in the side drawer)
2. You land back on the login screen
3. Log in as the next account from the table above

Because everything lives in Supabase, the state carries across logins — a
transfer the sender makes is already there when the receiver logs in. You can
also open a second browser window and stay logged in as two roles at once,
then hit the refresh icon on each dashboard to watch the transfer land.

## Presentation run-through (Phase 8)

1. **Sender** — log in as James Whitmore. Balance reads $500.00.
2. Send an amount to Uwase Aline. The fee and RWF preview update live.
   Confirm, and watch the balance drop by amount + fee.
3. **Exit** → log in as Uwase Aline. The transfer is already there, and the
   RWF balance has gone up.
4. Tap **Send to MoMo**. Status changes to *Sent to MoMo*, balance drops.
5. **Exit** → log in as the Admin. The transaction appears in the master
   table with the correct amounts and final status, and the stats reflect it.

To reset for a second run, re-run `supabase/schema.sql` — it restores the
starting $500 / 0 / 0 balances and clears the transaction history.

## Architecture

    lib/
      services/
        supabase_service.dart      All database access
        exchange_rate_service.dart Live USD→RWF rate, 1300 fallback
      providers/
        auth_provider.dart         Current user + account
        transaction_provider.dart  Transactions, receivers, balances
      screens/                     Login, sender, receiver, admin, profile
      models/                      AppUser, Account, AppTransaction, MomoPayout

Screens read cached lists from the providers during `build` and call the
provider's `load*` methods from `initState` and after actions.

### Money movement is atomic

Sending and cashing out each run as a single Postgres function
(`send_money`, `cash_out_to_momo`) rather than a sequence of client-side
updates. The debit, the credit, and the transaction record commit together or
not at all, so balances can never disagree with the transaction log — even if
the browser is closed mid-transfer.

`send_money` also locks the sender's account row and rejects a transfer that
exceeds the balance, so double-clicking Send cannot overdraw the account.

## Fees and exchange rate

- Fee: 1.5% of the amount sent, minimum $1.00
- Rate: fetched live, cached a few hours, falls back to 1 USD = 1,300 RWF

## A note on security

The anon key in `supabase_service.dart` is a public client-side key — shipping
it in a web app is normal and expected. Access is controlled by the row-level
security policies in `schema.sql`, which for this demo allow full read and
write to anyone with the key.

That is deliberate for a classroom demo with fake money and fake people. It is
not a pattern to reuse for anything holding real funds or real personal data,
where each user should only reach their own rows.
