import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

// Currency data model for backend compatibility
class CurrencyData {
  final int currentBalance;
  final int lifetimeEarned;
  final int todayEarned;
  final int dailyLimit;
  final int nextGoal;
  final String lastUpdateDate;
  final String userId; // For future backend sync
  final String dataHash; // For tamper detection
  final DateTime? lastAdWatched; // Add this field

  const CurrencyData({
    required this.currentBalance,
    required this.lifetimeEarned,
    required this.todayEarned,
    required this.dailyLimit,
    required this.nextGoal,
    required this.lastUpdateDate,
    required this.userId,
    required this.dataHash,
    this.lastAdWatched,
  });

  // Generate hash for tamper detection
  String _generateHash() {
    final dataString = '$currentBalance|$lifetimeEarned|$todayEarned|$dailyLimit|$nextGoal|$lastUpdateDate|$userId';
    return sha256.convert(utf8.encode(dataString + 'EMOTION_TRACKER_SALT')).toString();
  }

  // Verify data integrity
  bool get isValid => dataHash == _generateHash();

  Map<String, dynamic> toJson() {
    return {
      'currentBalance': currentBalance,
      'lifetimeEarned': lifetimeEarned,
      'todayEarned': todayEarned,
      'dailyLimit': dailyLimit,
      'nextGoal': nextGoal,
      'lastUpdateDate': lastUpdateDate,
      'userId': userId,
      'dataHash': dataHash,
      'lastAdWatched': lastAdWatched?.toIso8601String(),
    };
  }

  factory CurrencyData.fromJson(Map<String, dynamic> json) {
    return CurrencyData(
      currentBalance: json['currentBalance'] ?? 0,
      lifetimeEarned: json['lifetimeEarned'] ?? 0,
      todayEarned: json['todayEarned'] ?? 0,
      dailyLimit: json['dailyLimit'] ?? 100,
      nextGoal: json['nextGoal'] ?? 1000,
      lastUpdateDate: json['lastUpdateDate'] ?? DateTime.now().toIso8601String().split('T')[0],
      userId: json['userId'] ?? 'default_user',
      dataHash: json['dataHash'] ?? '',
      lastAdWatched: json['lastAdWatched'] != null ? DateTime.parse(json['lastAdWatched']) : null,
    );
  }

  CurrencyData copyWith({
    int? currentBalance,
    int? lifetimeEarned,
    int? todayEarned,
    int? dailyLimit,
    int? nextGoal,
    String? lastUpdateDate,
    String? userId,
    DateTime? lastAdWatched,
  }) {
    final newData = CurrencyData(
      currentBalance: currentBalance ?? this.currentBalance,
      lifetimeEarned: lifetimeEarned ?? this.lifetimeEarned,
      todayEarned: todayEarned ?? this.todayEarned,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      nextGoal: nextGoal ?? this.nextGoal,
      lastUpdateDate: lastUpdateDate ?? this.lastUpdateDate,
      userId: userId ?? this.userId,
      lastAdWatched: lastAdWatched ?? this.lastAdWatched,
      dataHash: '', // Will be generated
    );
    
    return CurrencyData(
      currentBalance: newData.currentBalance,
      lifetimeEarned: newData.lifetimeEarned,
      todayEarned: newData.todayEarned,
      dailyLimit: newData.dailyLimit,
      nextGoal: newData.nextGoal,
      lastUpdateDate: newData.lastUpdateDate,
      userId: newData.userId,
      lastAdWatched: newData.lastAdWatched,
      dataHash: newData._generateHash(),
    );
  }

  // Format balance for display (e.g., 1250 -> "1.2K")
  String get formattedBalance {
    if (currentBalance >= 1000000) {
      return '${(currentBalance / 1000000).toStringAsFixed(1)}M';
    } else if (currentBalance >= 1000) {
      return '${(currentBalance / 1000).toStringAsFixed(1)}K';
    }
    return currentBalance.toString();
  }

  // Format balance with token symbol for full display
  String get formattedBalanceWithSymbol {
    return '${currentBalance.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} SBD';
  }

  String get formattedLifetime {
    if (lifetimeEarned >= 1000000) {
      return '${(lifetimeEarned / 1000000).toStringAsFixed(1)}M';
    } else if (lifetimeEarned >= 1000) {
      return '${(lifetimeEarned / 1000).toStringAsFixed(1)}K';
    }
    return lifetimeEarned.toString();
  }

  // Format lifetime with token symbol for full display
  String get formattedLifetimeWithSymbol {
    return '${lifetimeEarned.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} SBD';
  }

  String get formattedNextGoal {
    if (nextGoal >= 1000000) {
      return '${(nextGoal / 1000000).toStringAsFixed(1)}M';
    } else if (nextGoal >= 1000) {
      return '${(nextGoal / 1000).toStringAsFixed(1)}K';
    }
    return nextGoal.toString();
  }

  // Format next goal with token symbol for full display
  String get formattedNextGoalWithSymbol {
    return '${nextGoal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} SBD';
  }

  // Progress toward next goal (0.0 to 1.0)
  double get goalProgress => nextGoal > 0 ? (currentBalance / nextGoal).clamp(0.0, 1.0) : 0.0;

  // --- COOLDOWN HELPERS FOR UI ---
  // Returns true if cooldown is active (less than 15 seconds since last ad watched)
  bool get isCooldownActive {
    if (lastAdWatched == null) return false;
    final now = DateTime.now();
    final cooldown = now.difference(lastAdWatched!);
    return cooldown.inSeconds < 15;
  }

  // Returns the remaining cooldown duration (Duration.zero if not active)
  Duration get displayCooldown {
    if (lastAdWatched == null) return Duration.zero;
    final now = DateTime.now();
    final cooldown = now.difference(lastAdWatched!);
    final remaining = Duration(seconds: 15) - cooldown;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // --- AVERAGE DAILY EARNINGS ---
  double get averageDailyEarnings {
    // Estimate days active based on lifetimeEarned and dailyLimit
    // (or you can store a daysActive field for more accuracy)
    if (lifetimeEarned == 0) return 0;
    int days = (lifetimeEarned / dailyLimit).ceil();
    if (days == 0) days = 1;
    return lifetimeEarned / days;
  }
}

// Currency state notifier
class CurrencyNotifier extends StateNotifier<CurrencyData> {
  final FlutterSecureStorage _storage;
  static const String _currencyKey = 'secure_currency_data';
  static const String _backupKey = 'currency_backup';

  CurrencyNotifier(this._storage) : super(
    const CurrencyData(
      currentBalance: 1250,
      lifetimeEarned: 8500,
      todayEarned: 25,
      dailyLimit: 100,
      nextGoal: 1500,
      lastUpdateDate: '',
      userId: 'default_user',
      dataHash: '',
      lastAdWatched: null,
    )
  ) {
    _loadCurrencyData();
  }

  Future<void> _loadCurrencyData() async {
    try {
      final dataJson = await _storage.read(key: _currencyKey);
      if (dataJson != null) {
        final data = CurrencyData.fromJson(json.decode(dataJson));
        
        // Verify data integrity
        if (!data.isValid) {
          await _restoreFromBackup();
          return;
        }

        // Check if it's a new day and reset daily earnings
        final today = DateTime.now().toIso8601String().split('T')[0];
        if (data.lastUpdateDate != today) {
          final updatedData = data.copyWith(
            todayEarned: 0,
            lastUpdateDate: today,
          );
          state = updatedData;
          await _saveCurrencyData(updatedData);
        } else {
          state = data;
        }
      } else {
        // Initialize with default data
        final today = DateTime.now().toIso8601String().split('T')[0];
        final initialData = state.copyWith(lastUpdateDate: today);
        state = initialData;
        await _saveCurrencyData(initialData);
      }
    } catch (e) {
      await _restoreFromBackup();
    }
  }

  Future<void> _saveCurrencyData(CurrencyData data) async {
    try {
      // Save main data
      await _storage.write(key: _currencyKey, value: json.encode(data.toJson()));
      
      // Create backup
      await _storage.write(key: _backupKey, value: json.encode(data.toJson()));
    } catch (e) {
      // Error saving currency data
    }
  }

  Future<void> _restoreFromBackup() async {
    try {
      final backupJson = await _storage.read(key: _backupKey);
      if (backupJson != null) {
        final backupData = CurrencyData.fromJson(json.decode(backupJson));
        if (backupData.isValid) {
          state = backupData;
          await _saveCurrencyData(backupData);
          return;
        }
      }
      
      // If backup is also corrupted, reset to default
      final today = DateTime.now().toIso8601String().split('T')[0];
      final defaultData = CurrencyData(
        currentBalance: 0,
        lifetimeEarned: 0,
        todayEarned: 0,
        dailyLimit: 100,
        nextGoal: 1000,
        lastUpdateDate: today,
        userId: 'default_user',
        dataHash: '',
        lastAdWatched: null,
      ).copyWith(); // This will generate the hash
      
      state = defaultData;
      await _saveCurrencyData(defaultData);
    } catch (e) {
      // Error restoring from backup
    }
  }

  // Add coins (e.g., from watching ads)
  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Check daily limit
    if (state.todayEarned + amount > state.dailyLimit) {
      final remainingAmount = state.dailyLimit - state.todayEarned;
      if (remainingAmount <= 0) return; // Daily limit reached
      amount = remainingAmount;
    }

    final updatedData = state.copyWith(
      currentBalance: state.currentBalance + amount,
      lifetimeEarned: state.lifetimeEarned + amount,
      todayEarned: state.todayEarned + amount,
      lastUpdateDate: today,
    );

    state = updatedData;
    await _saveCurrencyData(updatedData);
  }

  // Spend coins (e.g., for purchases)
  Future<bool> spendCoins(int amount) async {
    if (amount <= 0 || state.currentBalance < amount) return false;

    final updatedData = state.copyWith(
      currentBalance: state.currentBalance - amount,
    );

    state = updatedData;
    await _saveCurrencyData(updatedData);
    return true;
  }

  // Update daily limit (admin function)
  Future<void> updateDailyLimit(int newLimit) async {
    final updatedData = state.copyWith(dailyLimit: newLimit);
    state = updatedData;
    await _saveCurrencyData(updatedData);
  }

  // Update next goal
  Future<void> updateNextGoal(int newGoal) async {
    final updatedData = state.copyWith(nextGoal: newGoal);
    state = updatedData;
    await _saveCurrencyData(updatedData);
  }

  // Reset daily earnings
  Future<void> resetDailyEarnings() async {
    state = CurrencyData(
      currentBalance: state.currentBalance,
      lifetimeEarned: state.lifetimeEarned,
      todayEarned: 0,
      dailyLimit: state.dailyLimit,
      nextGoal: state.nextGoal,
      lastUpdateDate: DateTime.now().toIso8601String(),
      userId: state.userId,
      dataHash: state.dataHash,
      lastAdWatched: state.lastAdWatched,
    );
  }

  // Check if user can earn more coins today
  bool get canEarnMore => state.todayEarned < state.dailyLimit;
  
  // Get remaining daily earning capacity
  int get remainingDailyEarnings => state.dailyLimit - state.todayEarned;

  // Progress toward next goal (0.0 to 1.0)
  double get goalProgress => state.nextGoal > 0 ? (state.currentBalance / state.nextGoal).clamp(0.0, 1.0) : 0.0;

  // Export data for backend sync (future use)
  Map<String, dynamic> exportForBackend() {
    return state.toJson();
  }

  // Import data from backend (future use)
  Future<void> importFromBackend(Map<String, dynamic> serverData) async {
    try {
      final serverCurrency = CurrencyData.fromJson(serverData);
      if (serverCurrency.isValid) {
        state = serverCurrency;
        await _saveCurrencyData(serverCurrency);
      }
    } catch (e) {
      // Error importing from backend
    }
  }

  // Update last ad watched timestamp
  void updateLastAdWatched() {
    state = state.copyWith(lastAdWatched: DateTime.now());
  }
}

// Currency provider
final currencyProvider = StateNotifierProvider<CurrencyNotifier, CurrencyData>((ref) {
  final storage = ref.read(storageProvider);
  return CurrencyNotifier(storage);
});