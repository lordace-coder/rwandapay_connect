import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import '../services/exchange_rate_service.dart';

/// Holds the data the screens read, fetched from Supabase.
///
/// Screens read the cached lists synchronously during build and call the
/// `load*` methods from initState / after an action to refresh them.
class TransactionProvider extends ChangeNotifier {
  double _currentRate = ExchangeRateService.fallbackRate;
  bool _loadingRate = false;
  bool _processing = false;
  bool _loading = false;
  String? _error;

  List<AppTransaction> _transactions = [];
  List<AppUser> _receivers = [];
  List<AppUser> _nonAdminUsers = [];
  Map<String, Account> _accountsByUserId = {};

  double get currentRate => _currentRate;
  bool get loadingRate => _loadingRate;
  bool get processing => _processing;
  bool get loading => _loading;
  String? get error => _error;

  List<AppTransaction> get transactions => _transactions;
  List<AppUser> get receivers => _receivers;
  List<AppUser> get allNonAdminUsers => _nonAdminUsers;

  /// Loads the transactions this user is party to (as sender or receiver).
  Future<void> loadTransactionsForUser(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _transactions = await SupabaseService.getTransactionsForUser(userId);
    } catch (e) {
      _error = 'Could not load transactions.';
      debugPrint('loadTransactionsForUser failed: $e');
    }
    _loading = false;
    notifyListeners();
  }

  /// Loads every transaction on the platform (admin view).
  Future<void> loadAllTransactions() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _transactions = await SupabaseService.getAllTransactions();
    } catch (e) {
      _error = 'Could not load transactions.';
      debugPrint('loadAllTransactions failed: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadReceivers() async {
    try {
      _receivers = await SupabaseService.getReceivers();
      notifyListeners();
    } catch (e) {
      debugPrint('loadReceivers failed: $e');
    }
  }

  Future<void> loadNonAdminUsers() async {
    try {
      _nonAdminUsers = await SupabaseService.getNonAdminUsers();
      notifyListeners();
    } catch (e) {
      debugPrint('loadNonAdminUsers failed: $e');
    }
  }

  /// Loads every account so the admin users table can show balances.
  Future<void> loadAccounts() async {
    try {
      _accountsByUserId = await SupabaseService.getAllAccountsByUserId();
      notifyListeners();
    } catch (e) {
      debugPrint('loadAccounts failed: $e');
    }
  }

  Account? accountForUser(String userId) => _accountsByUserId[userId];

  Future<void> fetchExchangeRate() async {
    _loadingRate = true;
    notifyListeners();
    _currentRate = await ExchangeRateService.getUsdToRwfRate();
    _loadingRate = false;
    notifyListeners();
  }

  double calculateFee(double amount) {
    return ExchangeRateService.calculateFee(amount);
  }

  double calculateRwfAmount(double amountUsd) {
    return ExchangeRateService.convertToRwf(amountUsd, _currentRate);
  }

  /// Sends money. Returns the created transaction, or null if it failed —
  /// in which case [error] explains why.
  Future<AppTransaction?> sendMoney({
    required String senderId,
    required String receiverId,
    required double amountUsd,
  }) async {
    _processing = true;
    _error = null;
    notifyListeners();

    AppTransaction? txn;
    try {
      final fee = calculateFee(amountUsd);
      final amountRwf = calculateRwfAmount(amountUsd);
      final receiver = _receivers.where((u) => u.id == receiverId).firstOrNull;

      txn = await SupabaseService.createTransaction(
        senderId: senderId,
        receiverId: receiverId,
        amountUsd: amountUsd,
        feeUsd: fee,
        exchangeRate: _currentRate,
        amountRwf: amountRwf,
        momoNumber: receiver?.phone,
      );
    } catch (e) {
      _error = _friendlyError(e, fallback: 'Transfer failed. Please try again.');
      debugPrint('sendMoney failed: $e');
    }

    _processing = false;
    notifyListeners();
    return txn;
  }

  /// Cashes a received transaction out to MoMo. Returns true on success.
  Future<bool> sendToMomo(AppTransaction txn) async {
    _processing = true;
    _error = null;
    notifyListeners();

    var ok = false;
    try {
      // Simulated MoMo processing delay, so the demo shows a pending state.
      await Future.delayed(const Duration(seconds: 2));
      await SupabaseService.cashOutToMomo(txn.id);
      ok = true;
    } catch (e) {
      _error = _friendlyError(e, fallback: 'MoMo payout failed.');
      debugPrint('sendToMomo failed: $e');
    }

    _processing = false;
    notifyListeners();
    return ok;
  }

  /// Surfaces the message our database functions raise (e.g. "Insufficient
  /// balance") instead of a raw Postgres error string.
  String _friendlyError(Object e, {required String fallback}) {
    final text = e.toString();
    if (text.contains('Insufficient balance')) {
      return 'Insufficient balance for this transfer.';
    }
    if (text.contains('Already sent to MoMo')) {
      return 'This transfer has already been sent to MoMo.';
    }
    return fallback;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Drops all cached data. Called on logout so the next person to log in
  /// never sees the previous user's transactions while their own load.
  void clear() {
    _transactions = [];
    _receivers = [];
    _nonAdminUsers = [];
    _accountsByUserId = {};
    _error = null;
    _loading = false;
    _processing = false;
    notifyListeners();
  }

  // ── Admin stats, derived from the loaded transactions ──
  int get totalTransactions => _transactions.length;

  double get totalUsdSent =>
      _transactions.fold(0.0, (sum, t) => sum + t.amountUsd);

  double get totalRwfPaidOut =>
      _transactions.fold(0.0, (sum, t) => sum + t.amountRwf);

  int get totalUsers => _nonAdminUsers.length;

  AppUser? getUserById(String id) {
    return [..._nonAdminUsers, ..._receivers].where((u) => u.id == id).firstOrNull;
  }
}
