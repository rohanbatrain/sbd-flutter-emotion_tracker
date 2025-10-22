import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/sbd_tokens_provider.dart';
import 'package:emotion_tracker/providers/ad_provider.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/core/global_error_handler.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:local_auth/local_auth.dart';
import 'package:emotion_tracker/screens/currency/transactions/variant1.dart';
import 'package:emotion_tracker/widgets/transaction_card.dart';
import 'package:emotion_tracker/core/session_manager.dart';
import 'package:emotion_tracker/core/exceptions.dart';
import 'package:emotion_tracker/core/error_state.dart';
import 'dart:async';

// Timezone helper (from variant1)
const _tzAbbreviationMap = {
  'IST': 'Asia/Kolkata',
  'UTC': 'UTC',
  'GMT': 'Europe/London',
  'PST': 'America/Los_Angeles',
  'EST': 'America/New_York',
  'CST': 'America/Chicago',
  'MST': 'America/Denver',
  'JST': 'Asia/Tokyo',
  'CET': 'Europe/Paris',
  'EET': 'Europe/Bucharest',
};

String _mapAbbreviationToIana(String abbr) {
  return _tzAbbreviationMap[abbr.toUpperCase()] ?? abbr;
}

String formatTransactionTimestamp(String ts, String userTz) {
  try {
    String safeTs = ts;
    if (!ts.endsWith('Z') && !RegExp(r'[+-]\d{2}:?\d{2}').hasMatch(ts)) {
      safeTs = ts + 'Z';
    }
    final utc = DateTime.parse(safeTs).toUtc();
    String tzName = _mapAbbreviationToIana(userTz);
    if (tzName.isNotEmpty) {
      final location = tz.getLocation(tzName);
      final local = tz.TZDateTime.from(utc, location);
      return DateFormat('dd MMM yyyy • hh:mm a').format(local);
    } else {
      final local = utc.toLocal();
      return DateFormat('dd MMM yyyy • hh:mm a').format(local);
    }
  } catch (_) {
    return ts;
  }
}

class CurrencyScreenV2 extends ConsumerStatefulWidget {
  const CurrencyScreenV2({Key? key}) : super(key: key);

  @override
  ConsumerState<CurrencyScreenV2> createState() => _CurrencyScreenV2State();
}

class _CurrencyScreenV2State extends ConsumerState<CurrencyScreenV2>
    with TickerProviderStateMixin {
  int _selectedTab = 0;
  late AnimationController _confettiController;
  late AnimationController _coinBounceController;
  late Animation<double> _coinBounceAnimation;

  bool _showRewardSuccess = false;
  AdNotifier? _adNotifier;
  Timer? _cooldownTimer;
  Duration _cooldownRemaining = Duration.zero;
  String _walletUsername = '';
  bool _isLoadingUsername = true;

  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isSending = false;
  ErrorState? _errorState;

  // bool _showUsd = false; // Conversion feature commented out

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _coinBounceController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _coinBounceAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _coinBounceController, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _adNotifier = ref.read(adProvider.notifier);
      await _adNotifier?.loadRewardedAd(ref: ref);
      _startCooldownTimerIfNeeded();
      if (!mounted) return;
      setState(() {
        _isLoadingUsername = true;
      });
      await _loadWalletUsername();
      if (!mounted) return;
      setState(() {
        _isLoadingUsername = false;
      });
      if (!mounted) return;
      await _refreshWalletData();
    });
  }

  Future<void> _loadWalletUsername() async {
    final storage = ref.read(secureStorageProvider);
    final storedUsername = await storage.read(key: 'user_username');
    if (!mounted) {
      _walletUsername = storedUsername ?? '';
      return;
    }
    setState(() {
      _walletUsername = storedUsername ?? '';
    });
  }

  void _startCooldownTimerIfNeeded() {
    final cooldown = Duration(seconds: 15);
    if (_cooldownRemaining.inSeconds < cooldown.inSeconds) {
      _cooldownRemaining = cooldown - _cooldownRemaining;
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        // Guard: don't call setState if widget is disposed
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _cooldownRemaining = _cooldownRemaining - Duration(seconds: 1);
          if (_cooldownRemaining.isNegative ||
              _cooldownRemaining == Duration.zero) {
            _cooldownTimer?.cancel();
            _cooldownRemaining = Duration.zero;
          }
        });
      });
    } else {
      _cooldownRemaining = Duration.zero;
      _cooldownTimer?.cancel();
    }
  }

  Future<void> _refreshWalletData() async {
    setState(() {
      _errorState = null;
    });
    try {
      await ref.read(sbdTokensProvider.notifier).fetchBalance();
      await ref.read(sbdTokensProvider.notifier).fetchTransactions();
    } catch (e) {
      final errorState = GlobalErrorHandler.processError(e);
      setState(() {
        _errorState = errorState;
      });
      if (e is UnauthorizedException) {
        SessionManager.redirectToLogin(
          context,
          message: 'Session expired. Please log in again.',
        );
      }
    }
  }

  void _handleRetry() {
    _refreshWalletData();
    if (mounted) {
      GlobalErrorHandler.showErrorSnackbar(
        context,
        'Retrying request...',
        ErrorType.generic,
      );
    }
  }

  Future<bool> _authenticateForSend() async {
    final localAuth = LocalAuthentication();
    try {
      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Authenticate to send SBD tokens',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: false,
          useErrorDialogs: true,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    // Removed TabController dispose (no longer used)
    _confettiController.dispose();
    _coinBounceController.dispose();
    _cooldownTimer?.cancel();
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final sbdState = ref.watch(sbdTokensProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'SBD Wallet',
        showCurrency: false,
        showHamburger: false,
      ),
      body: _errorState != null
          ? ErrorStateWidget(
              error: _errorState!,
              onRetry: _handleRetry,
              customMessage: 'Unable to load wallet data.',
            )
          : sbdState.isLoading && sbdState.balance == null
          ? const LoadingStateWidget(message: 'Loading your wallet...')
          : IndexedStack(
              index: _selectedTab,
              children: [
                _buildWalletTab(theme, sbdState),
                _buildSendTab(theme, sbdState),
                _buildEarnTab(theme, sbdState),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
        backgroundColor: theme.cardColor,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: theme.hintColor,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send_rounded),
            label: 'Send',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_rounded),
            label: 'Earn',
          ),
        ],
      ),
    );
  }

  Widget _buildWalletTab(ThemeData theme, dynamic sbdState) {
    // final conversionRate = 0.0001; // Conversion feature commented out
    return RefreshIndicator(
      onRefresh: _refreshWalletData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Balance Card (Google Pay style) with SBD only (conversion feature commented out)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Balance',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'SBD',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sbdState.balance?.toString() ?? '--',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Available for transactions',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  // Conversion rate and USD toggle commented out
                  // if (_showUsd)
                  //   Padding(
                  //     padding: const EdgeInsets.only(top: 8.0),
                  //     child: Text(
                  //       '1 SBD = \$0.0001 USD',
                  //       style: TextStyle(
                  //         color: Colors.white.withOpacity(0.7),
                  //         fontSize: 12,
                  //         fontWeight: FontWeight.w500,
                  //       ),
                  //     ),
                  //   ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    theme: theme,
                    icon: Icons.qr_code_rounded,
                    label: 'My QR Code',
                    color: Colors.blue,
                    onTap: () => _showQrCodeDialog(_walletUsername),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    theme: theme,
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan QR',
                    color: Colors.green,
                    onTap: _showQrScanDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Account Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: theme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wallet Username',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (_isLoadingUsername)
                              Container(
                                height: 16,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: theme.dividerColor.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              )
                            else
                              Text(
                                _walletUsername,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy_rounded, size: 20),
                        color: theme.primaryColor,
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: _walletUsername),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Username copied!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Transactions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (sbdState.transactions != null &&
                    sbdState.transactions!.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TransactionsScreenV1(),
                        ),
                      );
                    },
                    child: Text(
                      'See All',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Transactions List
            if (sbdState.transactions != null &&
                sbdState.transactions!.isNotEmpty)
              ...sbdState.transactions!.take(5).map((tx) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MinimalTransactionCard(
                    tx: tx,
                    theme: theme,
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => _buildTransactionDetailsDialog(
                          tx: tx,
                          theme: theme,
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            if (sbdState.transactions != null && sbdState.transactions!.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 48,
                      color: theme.hintColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No transactions yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendTab(ThemeData theme, dynamic sbdState) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Send Form Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: theme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Send Tokens',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recipient Field
                  Text(
                    'Recipient',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _recipientController,
                    maxLength: 50,
                    decoration: InputDecoration(
                      hintText: 'Enter username',
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      counterText: '',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: theme.primaryColor,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.qr_code_scanner_rounded,
                          color: theme.primaryColor,
                        ),
                        onPressed: _showQrScanDialog,
                        tooltip: 'Scan QR Code',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount Field
                  Text(
                    'Amount',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      prefixIcon: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: theme.primaryColor,
                      ),
                      suffixText: 'SBD',
                      suffixStyle: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Available Balance Display
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.hintColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Available: ${sbdState.balance ?? 0} SBD',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Send Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _handleSendTokens,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.send_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Send Tokens',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.security_rounded, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All transactions require biometric authentication',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSendTokens() async {
    final toUser = _recipientController.text.trim();
    final amountText = _amountController.text.trim();
    final sbdState = ref.read(sbdTokensProvider);

    if (toUser.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter recipient and amount.')),
      );
      return;
    }

    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than 0.'),
        ),
      );
      return;
    }

    if (sbdState.balance != null && amount > (sbdState.balance ?? 0)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Insufficient balance.')));
      return;
    }

    final didAuth = await _authenticateForSend();
    if (!didAuth) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication failed. Cannot send tokens.'),
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    final success = await ref
        .read(sbdTokensProvider.notifier)
        .sendTokens(toUser: toUser, amount: amount);
    setState(() => _isSending = false);

    if (success) {
      _amountController.clear();
      _recipientController.clear();
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final theme = Theme.of(context);
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Sent Successfully!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You sent $amount SBD to $toUser.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      await ref.read(sbdTokensProvider.notifier).fetchBalance();
      await ref.read(sbdTokensProvider.notifier).fetchTransactions();
      setState(() => _selectedTab = 0); // Switch back to Wallet tab
    } else {
      final err = ref.read(sbdTokensProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${err ?? 'Unknown error'}')),
      );
    }
  }

  Widget _buildEarnTab(ThemeData theme, dynamic sbdState) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Earn Header
              Text(
                'Earn Rewards',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Watch ads to earn SBD tokens instantly',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 24),

              // Watch Ad Card (Google Pay style)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade400,
                      Colors.deepPurple.shade600,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_circle_filled_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Watch & Earn',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Get +1 SBD per video ad',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed:
                                  (_adNotifier?.isRewardedAdReady ?? false)
                                  ? _watchAd
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.deepPurple.shade600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow_rounded, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    (_adNotifier?.isRewardedAdReady ?? false)
                                        ? 'Watch Ad Now'
                                        : 'Loading Ad...',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Info Cards
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: theme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How it works',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      theme: theme,
                      icon: Icons.smart_display_rounded,
                      text: 'Watch a short video advertisement',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      theme: theme,
                      icon: Icons.verified_rounded,
                      text: 'Ad completion verified by server',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      theme: theme,
                      icon: Icons.account_balance_wallet_rounded,
                      text: 'Instantly receive 1 SBD token',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Reward Success Overlay
        if (_showRewardSuccess) _buildRewardOverlay(theme, sbdState),
      ],
    );
  }

  Widget _buildInfoRow({
    required ThemeData theme,
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }

  void _watchAd() async {
    if (_adNotifier?.isRewardedAdReady != true) {
      _showAdNotReadyDialog();
      return;
    }

    await _adNotifier?.showRewardedAd(
      onUserEarnedReward: (_) {},
      onAdClosed: () async {
        await _adNotifier?.loadRewardedAd(ref: ref);
      },
      onRewardCallback: (username) async {
        _handleAdReward();
      },
      ref: ref,
    );
  }

  void _handleAdReward() async {
    // Ensure widget is still mounted before updating state or showing UI
    if (!mounted) return;
    setState(() {
      _showRewardSuccess = true;
    });

    // Refresh wallet data (await so we catch potential errors)
    try {
      await ref.read(sbdTokensProvider.notifier).fetchBalance();
      await ref.read(sbdTokensProvider.notifier).fetchTransactions();
    } catch (_) {
      // ignore, UI will show latest cached state or error elsewhere
    }

    _startCooldownTimerIfNeeded();
    // Start animations but guard against disposed controllers
    try {
      _confettiController.forward();
    } catch (_) {}
    try {
      _coinBounceController.forward();
    } catch (_) {}
  }

  void _showAdNotReadyDialog() {
    final theme = ref.read(currentThemeProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('Ad Not Ready', style: theme.textTheme.titleLarge),
        content: Text(
          'The ad is still loading. Please try again in a moment.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _adNotifier?.loadRewardedAd(ref: ref);
            },
            child: Text('OK', style: TextStyle(color: theme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardOverlay(ThemeData theme, dynamic sbdState) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.3),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withOpacity(0.2),
                      Colors.orange.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: AnimatedBuilder(
                  animation: _coinBounceAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _coinBounceAnimation.value,
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.amber,
                        size: 64,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Congratulations!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "You've Earned +1 SBD!",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _watchAd,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Watch Again'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showRewardSuccess = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // QR Code Dialog
  void _showQrCodeDialog(String username) {
    final theme = ref.read(currentThemeProvider);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Wallet QR Code',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: username,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                username,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan this QR to receive tokens',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // QR Scan Dialog
  void _showQrScanDialog() {
    final theme = ref.read(currentThemeProvider);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 320,
          height: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Scan Wallet QR',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileScanner(
                    controller: MobileScannerController(
                      formats: [BarcodeFormat.qrCode],
                    ),
                    fit: BoxFit.cover,
                    onDetect: (capture) {
                      final barcode = capture.barcodes.first;
                      final String? code = barcode.rawValue;
                      if (code != null &&
                          code.length <= 50 &&
                          RegExp(r'^[a-zA-Z0-9._-]{1,50}$').hasMatch(code)) {
                        // Avoid using context if widget was disposed or dialog closed
                        if (!mounted) return;
                        try {
                          Navigator.of(context).pop();
                        } catch (_) {}
                        _recipientController.text = code;
                        if (mounted) {
                          try {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Username scanned: $code'),
                              ),
                            );
                          } catch (_) {}
                        }
                      }
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Transaction Details Dialog
  Widget _buildTransactionDetailsDialog({
    required Map<String, dynamic> tx,
    required ThemeData theme,
  }) {
    return TransactionDetailsDialog(
      tx: tx,
      theme: theme,
      onNoteSaved: (note) async {
        setState(() {
          tx['note'] = note;
        });
        if (tx['transaction_id'] != null && note.isNotEmpty) {
          await ref
              .read(sbdTokensProvider.notifier)
              .updateTransactionNote(
                transactionId: tx['transaction_id'],
                note: note,
              );
        }
      },
    );
  }
}

// Transaction Details Dialog Widget
class TransactionDetailsDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> tx;
  final ThemeData theme;
  final void Function(String note) onNoteSaved;

  const TransactionDetailsDialog({
    Key? key,
    required this.tx,
    required this.theme,
    required this.onNoteSaved,
  }) : super(key: key);

  @override
  ConsumerState<TransactionDetailsDialog> createState() =>
      _TransactionDetailsDialogState();
}

class _TransactionDetailsDialogState
    extends ConsumerState<TransactionDetailsDialog> {
  late TextEditingController _noteController;
  bool _isEditing = false;
  String? _originalNote;

  @override
  void initState() {
    super.initState();
    _originalNote = widget.tx['note'] ?? '';
    _noteController = TextEditingController(text: _originalNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    final theme = widget.theme;
    final isSend = tx['type'] == 'send';
    final isReceive = tx['type'] == 'receive';
    final otherUser = isSend ? tx['to'] : (isReceive ? tx['from'] : '');
    final amount = tx['amount'] ?? 0;
    final timestamp = tx['timestamp'] ?? '';
    final transactionId = tx['transaction_id'] ?? '';
    final tzString = ref.watch(timezoneProvider);
    final formattedTimestamp = formatTransactionTimestamp(timestamp, tzString);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.12),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSend
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSend
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: isSend ? Colors.red : Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isSend ? 'Sent' : 'Received',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow(
                theme: theme,
                icon: Icons.account_balance_wallet_rounded,
                label: 'Amount',
                value: '$amount SBD',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                theme: theme,
                icon: Icons.person_outline,
                label: isSend ? 'To' : 'From',
                value: otherUser,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                theme: theme,
                icon: Icons.access_time,
                label: 'Time',
                value: formattedTimestamp,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.numbers, color: theme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text('ID:', style: theme.textTheme.bodyMedium),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      transactionId,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 18),
                    color: theme.primaryColor,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: transactionId));
                      if (mounted) {
                        try {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaction ID copied!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        } catch (_) {}
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Note',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!_isEditing)
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => setState(() => _isEditing = true),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      Column(
                        children: [
                          TextField(
                            controller: _noteController,
                            decoration: InputDecoration(
                              hintText: 'Add a note',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            maxLines: 2,
                            autofocus: true,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    widget.onNoteSaved(_noteController.text);
                                    if (mounted) {
                                      setState(() {
                                        _isEditing = false;
                                        _originalNote = _noteController.text;
                                      });
                                      try {
                                        Navigator.of(context).pop();
                                      } catch (_) {}
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                  ),
                                  child: const Text('Save'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _noteController.text =
                                          _originalNote ?? '';
                                      _isEditing = false;
                                    });
                                  },
                                  child: const Text('Cancel'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Text(
                        (_originalNote?.isNotEmpty ?? false)
                            ? _originalNote!
                            : 'No note added.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: (_originalNote?.isNotEmpty ?? false)
                              ? theme.colorScheme.onSurface
                              : theme.hintColor,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: theme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text('$label:', style: theme.textTheme.bodyMedium),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
