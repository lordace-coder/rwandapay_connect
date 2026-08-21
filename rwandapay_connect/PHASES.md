# RwandaPay Connect — Build Phases

| Phase | What it covers | How you'll know it's really done |
|-------|---------------|----------------------------------|
| 0 | Project setup — folder structure, dependencies installed, dev server boots | Dev server starts with no errors; a blank/placeholder page loads in the browser |
| 1 | Database schema + seed data — the 4 demo accounts exist with correct starting balances | You can open the database (or an admin view) and see all 4 accounts with the exact details from Part One |
| 2 | Login / authentication — all 3 roles can log in with their seeded credentials and land on a role-specific dashboard | You personally log in as each of the 4 accounts in the browser and reach the correct dashboard each time |
| 3 | Sender flow — dashboard, "Send Money" form, live fee + exchange rate preview, confirm button, balance deduction | Logged in as Sender, you send a test amount and watch your own balance drop by the correct amount |
| 4 | Receiver flow — dashboard, incoming transaction appears, balance increases, "Send to MoMo" button changes status | Logged in as a Receiver, you see the transaction from Phase 3 arrive, and clicking "Send to MoMo" updates its status correctly |
| 5 | Admin flow — summary stats, master transaction table, users table | Logged in as Admin, you can see the exact transaction from Phases 3–4 in the master table, with correct amounts and status |
| 6 | Verification / KYC screen (simulated) — profile page with Verified badge and mock ID section | Each seeded account's profile page shows a Verified badge and a mock ID document section |
| 7 | Visual design — apply the color palette, fonts, and layout style from Part One, Section 9, across all screens | All screens visually match — consistent colors, fonts, and card styling |
| 8 | Full end-to-end rehearsal — Sender sends → Receiver receives → Receiver cashes out to MoMo → Admin sees everything | You personally run this exact sequence live, start to finish, with no errors, the way you will during the real presentation |

## Demo Accounts

### Sender (United States) — 1 account
- **Full Name:** James Whitmore
- **Email:** james.whitmore@demo-rwandapay.com
- **Password:** Sender@2026
- **Account No:** RWC-US-0001
- **Country:** United States
- **Address:** 4821 Maple Grove Ave, Atlanta, GA 30301, USA
- **Phone:** +1 (404) 555-0142
- **ID Type:** US Driver's License
- **ID Number:** GA-04559213
- **Starting Balance:** $500.00 USD
- **Verification:** Verified

### Receiver #1 (Rwanda)
- **Full Name:** Uwase Aline
- **Email:** uwase.aline@demo-rwandapay.com
- **Password:** Receiver1@2026
- **Account No:** RWC-RW-0001
- **Country:** Rwanda
- **Address:** KG 231 St, Kimironko, Gasabo District, Kigali
- **Phone:** +250 788 123 456
- **ID Type:** Rwandan National ID
- **ID Number:** 1 1990 8 0123456 0 12
- **MoMo Provider:** MTN MoMo
- **Starting Balance:** 0 RWF
- **Verification:** Verified

### Receiver #2 (Rwanda)
- **Full Name:** Niyonzima Eric
- **Email:** niyonzima.eric@demo-rwandapay.com
- **Password:** Receiver2@2026
- **Account No:** RWC-RW-0002
- **Country:** Rwanda
- **Address:** KG 15 Ave, Remera, Gasabo District, Kigali
- **Phone:** +250 788 987 654
- **ID Type:** Rwandan National ID
- **ID Number:** 1 1993 7 0654321 0 27
- **MoMo Provider:** MTN MoMo
- **Starting Balance:** 0 RWF
- **Verification:** Verified

### Admin — 1 account
- **Full Name:** Donald Ehizode (Platform Admin)
- **Email:** admin@demo-rwandapay.com
- **Password:** Admin@2026
- **Account No:** RWC-ADM-0001

## Fee Structure
- Fee: 1.5% of amount sent
- Minimum fee: $1.00
- Clearly shown before confirmation

## Exchange Rate
- Live API: https://api.exchangerate-api.com/v4/latest/USD (or frankfurter.app)
- Fallback: 1 USD = 1,300 RWF
- Cache for a few hours

## Color Palette
- Navy: #1B2A4A (primary brand, headers, buttons)
- Gold: #C9A227 (accent, highlights, CTAs)
- Light Grey: #F7F8FA (page background)
- White: #FFFFFF (card backgrounds)
- Muted Grey: #5A6472 (secondary text)

## Typography
- Headings: Georgia (web-safe fallback for Cambria)
- Body/UI: Inter or Segoe UI (clean sans-serif)
