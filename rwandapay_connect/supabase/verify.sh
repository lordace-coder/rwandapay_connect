#!/usr/bin/env bash
# Verifies the Supabase backend is set up correctly.
# Run after pasting supabase/schema.sql into the Supabase SQL Editor.
#
#   ./supabase/verify.sh

set -u

URL="https://gocqqslneewxigrlfwuj.supabase.co"
KEY="sb_publishable_Jx9AebYK0GcUKOLeQ3n0lQ_kiSu6HW0"

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
# Call each with its real argument names and a deliberately absent id: a
# present function rejects the row itself, a missing one reports PGRST202.
# (Probing with '{}' is not enough — PostgREST also returns PGRST202 when a
# function exists but its required named arguments were not supplied.)
probe_fn() {
  local fn="$1" args="$2" body
  body=$(curl -s -X POST "$URL/rest/v1/rpc/$fn" \
    -H "apikey: $KEY" -H "Authorization: Bearer $KEY" \
    -H "Content-Type: application/json" -d "$args")
  if echo "$body" | grep -q 'PGRST202'; then
    check bad "$fn — missing (re-run supabase/schema.sql)"
  else
    check ok "$fn"
  fi
}
absent="00000000-0000-4000-8000-000000000000"
probe_fn send_money "$(printf '{"p_sender_id":"%s","p_receiver_id":"%s","p_amount_usd":0,"p_fee_usd":0,"p_exchange_rate":0,"p_amount_rwf":0,"p_momo_number":""}' "$absent" "$absent")"
probe_fn cash_out_to_momo "$(printf '{"p_transaction_id":"%s"}' "$absent")"
echo

if [ "$fail" -eq 0 ]; then
  printf '\033[32mAll checks passed — the backend is ready.\033[0m\n\n'
else
  printf '\033[31mSome checks failed. Re-run supabase/schema.sql in the SQL Editor:\033[0m\n'
  printf '  https://supabase.com/dashboard/project/gocqqslneewxigrlfwuj/sql/new\n\n'
fi

exit "$fail"
