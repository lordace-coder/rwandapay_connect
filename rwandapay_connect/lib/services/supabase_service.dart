import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../models/account.dart';
import '../models/transaction.dart';


class SupabaseService {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  // Project credentials. The publishable key is a public, client-side key: it
  // is safe to ship in the app, and access is governed by the RLS policies in
  // supabase/schema.sql.
  static const String _supabaseUrl = 'https://gocqqslneewxigrlfwuj.supabase.co';
  static const String _supabasePublishableKey =
      'sb_publishable_Jx9AebYK0GcUKOLeQ3n0lQ_kiSu6HW0';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (_initialized) return;

    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabasePublishableKey,
    );
    _initialized = true;
  }

  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // ── Auth ──────────────────────────────────────────────
  static Future<AppUser?> authenticateUser(String email, String password) async {
    final hash = hashPassword(password);
    final response = await client
        .from('users')
        .select()
        .eq('email', email.toLowerCase())
        .eq('password_hash', hash)
        .maybeSingle();

    if (response == null) return null;
    return _userFromMap(response);
  }

  // ── Users ─────────────────────────────────────────────
  static Future<AppUser?> getUserById(String id) async {
    final response =
        await client.from('users').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return _userFromMap(response);
  }

  static Future<List<AppUser>> getReceivers() async {
    final response =
        await client.from('users').select().eq('role', 'receiver');
    return (response as List).map((r) => _userFromMap(r)).toList();
  }

  /// Looks up a user by the account number encoded in a payment QR code.
  /// Returns null when no such account exists, so the scanner can report an
  /// unrecognised code instead of failing.
  static Future<AppUser?> getUserByAccountNumber(String accountNumber) async {
    final response = await client
        .from('users')
        .select()
        .eq('account_number', accountNumber)
        .maybeSingle();
    if (response == null) return null;
    return _userFromMap(response);
  }

  static Future<List<AppUser>> getNonAdminUsers() async {
    final response =
        await client.from('users').select().neq('role', 'admin');
    return (response as List).map((r) => _userFromMap(r)).toList();
  }

  // ── Accounts ──────────────────────────────────────────
  static Future<Account?> getAccountByUserId(String userId) async {
    final response = await client
        .from('accounts')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (response == null) return null;
    return _accountFromMap(response);
  }

  /// Every account on the platform, keyed by the owning user's id.
  /// Used by the admin users table so it doesn't fetch one account per row.
  static Future<Map<String, Account>> getAllAccountsByUserId() async {
    final response = await client.from('accounts').select();
    return {
      for (final r in (response as List))
        (r['user_id'] as String): _accountFromMap(r)
    };
  }

  static Future<void> updateAccountBalance(
      String accountId, double newBalance) async {
    await client.from('accounts').update({
      'balance': newBalance,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', accountId);
  }

  // ── Transactions ──────────────────────────────────────
  static Future<List<AppTransaction>> getTransactionsForUser(
      String userId) async {
    final response = await client
        .from('transactions')
        .select()
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('created_at', ascending: false);
    return (response as List).map((r) => _transactionFromMap(r)).toList();
  }

  static Future<List<AppTransaction>> getAllTransactions() async {
    final response = await client
        .from('transactions')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((r) => _transactionFromMap(r)).toList();
  }

  /// Sends money via the `send_money` database function, so the sender debit,
  /// receiver credit, and transaction row all commit together or not at all.
  static Future<AppTransaction> createTransaction({
    required String senderId,
    required String receiverId,
    required double amountUsd,
    required double feeUsd,
    required double exchangeRate,
    required double amountRwf,
    String? momoNumber,
  }) async {
    final response = await client.rpc('send_money', params: {
      'p_sender_id': senderId,
      'p_receiver_id': receiverId,
      'p_amount_usd': amountUsd,
      'p_fee_usd': feeUsd,
      'p_exchange_rate': exchangeRate,
      'p_amount_rwf': amountRwf,
      'p_momo_number': momoNumber,
    });

    return _transactionFromMap(Map<String, dynamic>.from(response as Map));
  }

  static Future<void> updateTransactionStatus(
      String txnId, String newStatus) async {
    await client.from('transactions').update({
      'status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', txnId);
  }

  // ── MoMo Payouts ─────────────────────────────────────
  /// Cashes a received transaction out to MoMo via the `cash_out_to_momo`
  /// database function: status change, payout record, and balance debit all
  /// commit together.
  static Future<AppTransaction> cashOutToMomo(String transactionId) async {
    final response = await client.rpc('cash_out_to_momo', params: {
      'p_transaction_id': transactionId,
    });

    return _transactionFromMap(Map<String, dynamic>.from(response as Map));
  }

  // ── Stats ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getAdminStats() async {
    final transactions = await getAllTransactions();
    final users = await getNonAdminUsers();

    return {
      'totalTransactions': transactions.length,
      'totalUsdSent': transactions.fold(0.0, (sum, t) => sum + t.amountUsd),
      'totalRwfPaidOut': transactions.fold(0.0, (sum, t) => sum + t.amountRwf),
      'totalUsers': users.length,
    };
  }

  // ── Mappers ───────────────────────────────────────────
  static AppUser _userFromMap(Map<String, dynamic> m) {
    return AppUser(
      id: m['id'],
      fullName: m['full_name'] ?? '',
      email: m['email'] ?? '',
      passwordHash: m['password_hash'] ?? '',
      role: m['role'] ?? '',
      country: m['country'] ?? '',
      phone: m['phone'] ?? '',
      accountNumber: m['account_number'] ?? '',
      idType: m['id_type'] ?? '',
      idNumber: m['id_number'] ?? '',
      verificationStatus: m['verification_status'] ?? 'verified',
      address: m['address'],
      momoProvider: m['momo_provider'],
      createdAt: DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  static Account _accountFromMap(Map<String, dynamic> m) {
    return Account(
      id: m['id'],
      userId: m['user_id'] ?? '',
      currency: m['currency'] ?? '',
      balance: (m['balance'] as num).toDouble(),
      updatedAt: DateTime.tryParse(m['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  static AppTransaction _transactionFromMap(Map<String, dynamic> m) {
    return AppTransaction(
      id: m['id'],
      senderId: m['sender_id'] ?? '',
      receiverId: m['receiver_id'] ?? '',
      amountUsd: (m['amount_usd'] as num).toDouble(),
      feeUsd: (m['fee_usd'] as num).toDouble(),
      exchangeRateUsed: (m['exchange_rate_used'] as num).toDouble(),
      amountRwf: (m['amount_rwf'] as num).toDouble(),
      status: m['status'] ?? 'sent',
      momoNumberUsed: m['momo_number_used'],
      createdAt: DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(m['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}
