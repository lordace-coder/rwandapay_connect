#!/usr/bin/env bash
# Verifies the Supabase backend is set up correctly.
# Run after pasting supabase/schema.sql into the Supabase SQL Editor.
#
#   ./supabase/verify.sh

set -u

URL="https://dohwtewodbheczloukyh.supabase.co"
KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvaHd0ZXdvZGJoZWN6bG91a3loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcxMzc4ODQsImV4cCI6MjEwMjcxMzg4NH0._rmqTGIrjlJSdFIAlDGFOLa5MCdkJdAUd2-zbNqE3Dc"

api() {
  local path="$1"; shift
  curl -s "$URL/rest/v1/$path" \
    -H "apikey: $KEY" -H "Authorization: Bearer $KEY" "$@"
}

fail=0
check() {
  if [ "$1" = "ok" ]; then
    printf '  \033[32m✓\033[0m %s\n' "$2"
  else
    printf '  \033[31m✗\033[0m %s\n' "$2"
    fail=1
  fi
}

echo
echo "Verifying RwandaPay Connect backend"
echo "=================================="
echo

# 1. Tables exist
echo "Tables:"
for t in users accounts transactions momo_payouts; do
  body=$(api "$t?select=*&limit=1")
  if echo "$body" | grep -q 'PGRST205'; then
    check bad "$t — missing (run supabase/schema.sql)"
  else
    check ok "$t"
  fi
done
echo

# 2. Seeded users
echo "Demo accounts:"
users=$(api "users?select=email,role,account_number&order=account_number")
for email in james.whitmore uwase.aline niyonzima.eric admin; do
  if echo "$users" | grep -q "$email@demo-rwandapay.com"; then
    check ok "$email@demo-rwandapay.com"
  else
    check bad "$email@demo-rwandapay.com — not seeded"
  fi
done
echo

# 3. Password hashes match PHASES.md
echo "Passwords:"
verify_pw() {
  local email="$1" password="$2"
  local expected actual
  expected=$(printf '%s' "$password" | sha256sum | cut -d' ' -f1)
  actual=$(api "users?select=password_hash&email=eq.$email" \
    | grep -o '"password_hash":"[^"]*"' | cut -d'"' -f4)
  if [ "$expected" = "$actual" ]; then
    check ok "$password"
  else
    check bad "$password — hash mismatch, login will fail"
  fi
}
verify_pw "james.whitmore@demo-rwandapay.com" "Sender@2026"
verify_pw "uwase.aline@demo-rwandapay.com"    "Receiver1@2026"
verify_pw "niyonzima.eric@demo-rwandapay.com" "Receiver2@2026"
verify_pw "admin@demo-rwandapay.com"          "Admin@2026"
echo

# 4. Starting balances
echo "Starting balances:"
balances=$(api "accounts?select=currency,balance")
echo "$balances" | grep -q '"currency":"USD","balance":500' \
  && check ok "Sender: \$500.00 USD" \
  || check bad "Sender: expected \$500.00 USD, got: $balances"
rwf_zero=$(echo "$balances" | grep -o '"currency":"RWF","balance":0' | wc -l)
[ "$rwf_zero" -eq 2 ] \
  && check ok "Both receivers: 0 RWF" \
  || check bad "Receivers: expected two accounts at 0 RWF"
echo

# 5. Money-movement functions exist
echo "Database functions:"
for fn in send_money cash_out_to_momo; do
  body=$(curl -s -X POST "$URL/rest/v1/rpc/$fn" \
    -H "apikey: $KEY" -H "Authorization: Bearer $KEY" \
    -H "Content-Type: application/json" -d '{}')
  # A missing function reports PGRST202; a present one complains about args.
  if echo "$body" | grep -q 'PGRST202'; then
    check bad "$fn — missing (re-run supabase/schema.sql)"
  else
    check ok "$fn"
  fi
done
echo

if [ "$fail" -eq 0 ]; then
  printf '\033[32mAll checks passed — the backend is ready.\033[0m\n\n'
else
  printf '\033[31mSome checks failed. Re-run supabase/schema.sql in the SQL Editor:\033[0m\n'
  printf '  https://supabase.com/dashboard/project/dohwtewodbheczloukyh/sql/new\n\n'
fi

exit "$fail"
