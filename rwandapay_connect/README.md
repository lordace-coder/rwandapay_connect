# RwandaPay Connect

A simulated cross-border remittance demo: money is sent from the United States
to Rwanda, converted USD → RWF, and cashed out to MTN MoMo. A receiver can
show a **QR payment code** and the sender pays it by **scanning with their
camera**. Flutter frontend — runs on the web and on Android — with a Supabase
(Postgres) backend.

No real payment processor, bank API, or MTN MoMo API is involved. All "money"
lives in this project's own database.

## Setup

### 1. Create the database

Open the SQL Editor for the Supabase project:

    https://supabase.com/dashboard/project/gocqqslneewxigrlfwuj/sql/new

Paste the entire contents of [`supabase/schema.sql`](supabase/schema.sql) and
click **Run**. This creates the tables, the money-movement functions, and the
four demo accounts.

The script drops and recreates everything, so running it again resets the demo
to its starting state — useful for rehearsing the presentation.

### 2. Verify it worked

    ./supabase/verify.sh

Every line should be a green ✓. If not, the script says what to fix.

### 3. Run the app

The app runs on the web and on Android.

    flutter run -d chrome     # web
    flutter run -d <device>   # Android phone or emulator

`flutter devices` lists what is currently attached.

**Camera access.** Scan to Pay needs a camera, and the two platforms gate it
differently:

- **Web** — browsers only release the camera on a *secure origin*.
  `flutter run -d chrome` serves from `localhost`, which counts as secure, so
  scanning works in development with no setup. A deployed build must be served
  over HTTPS or the camera will not open.
- **Android** — the app asks for camera permission the first time you open
  Scan to Pay. Granting it is enough; nothing else to configure.

Either way, if the camera cannot be opened the scanner says so and offers
manual code entry instead, so the demo is never blocked.

### Building for Android

    flutter build apk --debug      # fastest, for sideloading onto a phone
    flutter build apk --release    # smaller, minified

The APK lands in `build/app/outputs/flutter-apk/`. Copy it to a phone and open
it (Android will ask you to allow installing from unknown sources).

Release builds are signed with the **debug keystore** — deliberate, so the
build works on any machine without a keystore to hand. That is fine for
sideloading and for this demo; a Play Store upload would need a real signing
config in `android/app/build.gradle.kts`.

The first Android build is slow (10–20 minutes on a modest laptop) because
Gradle downloads its toolchain and compiles everything from scratch; later
builds reuse both and take a fraction of that. `android/gradle.properties`
caps the Gradle JVM at 2 GB — the Flutter template ships `-Xmx8G`, which is
more than some laptops physically have and sends them into swap mid-build.
Raise it if you build on a machine with plenty of RAM.

Running on a real phone is the best way to demo Scan to Pay: show the
receiver's QR on the laptop screen and scan it with the phone.

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

## Scan to Pay

Instead of picking a receiver from a list, the sender can point their camera at
the receiver's QR code.

**Receiver** — *Show My Payment Code* on the dashboard (or **My Code** in the
bottom nav) displays their QR. A toggle turns it into a request for a specific
amount, which prefills the sender's amount field. The raw code is printed
under the QR with a copy button, for when a camera is not available.

**Sender** — **Scan** on the dashboard (or in the bottom nav) opens the camera.
When a code resolves, a sheet confirms who is being paid before anything is
sent; continuing opens the normal Send Money screen with the receiver — and any
requested amount — already filled in. The sender still reviews the fee and the
RWF preview and presses **Confirm & Send**, so scanning replaces the lookup
step, never the confirmation step.

### What a code contains

    rwandapay://pay?acct=RWC-RW-0001&name=Uwase%20Aline&amount=25.00

`amount` is optional — without it the sender chooses the amount. Only `acct` is
trusted: the app looks that account up in the database and uses the record it
finds, so the name embedded in a code cannot misrepresent who gets paid.

Codes are rejected, with an on-screen reason, when they are not RwandaPay codes,
name an account that does not exist, belong to the scanner themselves, or belong
to an account that cannot receive money.

### If the camera will not open

Permission denied, no webcam, or a non-HTTPS origin all land on the same
fallback: the screen explains the problem and **Enter code manually** accepts a
pasted code, which then behaves exactly like a scanned one. Worth knowing
before presenting on an unfamiliar machine.

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

### Demonstrating Scan to Pay

Best version, and what the Android build is for: run the app on a **phone**,
logged in as James (sender). On the laptop, log in as Uwase and open **Show My
Payment Code**. Point the phone at the laptop screen — it scans, confirms who is
being paid, and drops into Send Money with her details filled in.

With only a laptop, open two browser windows side by side and use **Enter code
manually**, pasting the code printed under the receiver's QR. The rest of the
flow is identical.

## Architecture

    lib/
      services/
        supabase_service.dart      All database access
        exchange_rate_service.dart Live USD→RWF rate, 1300 fallback
      providers/
        auth_provider.dart         Current user + account
        transaction_provider.dart  Transactions, receivers, balances
      screens/                     Login, sender, receiver, admin, profile
        sender/scan_to_pay_screen.dart  Camera QR scanner
        receiver/my_qr_screen.dart      The receiver's own QR code
      models/                      AppUser, Account, AppTransaction,
                                   MomoPayout, PaymentQr

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

## Tests

    flutter test

Covers QR payload encoding and parsing — including malformed and hostile codes
— and that the login screen renders. `flutter analyze` reports no issues.

## Fees and exchange rate

- Fee: 1.5% of the amount sent, minimum $1.00
- Rate: fetched live, cached a few hours, falls back to 1 USD = 1,300 RWF

## A note on security

The publishable key in `supabase_service.dart` is a public client-side key —
shipping it in a web app is normal and expected. Access is controlled by the row-level
security policies in `schema.sql`, which for this demo allow full read and
write to anyone with the key.

That is deliberate for a classroom demo with fake money and fake people. It is
not a pattern to reuse for anything holding real funds or real personal data,
where each user should only reach their own rows.
