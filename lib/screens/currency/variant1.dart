import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/sbd_tokens_provider.dart';
import 'package:emotion_tracker/providers/ad_provider.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
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
import 'dart:async';

// Timezone abbreviation to IANA map (from login_history_screen.dart)
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
  // Add more as needed
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

class CurrencyScreenV1 extends ConsumerStatefulWidget {
  const CurrencyScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<CurrencyScreenV1> createState() => _CurrencyScreenV1State();
}

class _CurrencyScreenV1State extends ConsumerState<CurrencyScreenV1>
    with TickerProviderStateMixin {
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
    _coinBounceAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _coinBounceController,
      curve: Curves.elasticOut,
    ));

    // Initialize ad provider and load rewarded ad with SSV
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _adNotifier = ref.read(adProvider.notifier);
      await _adNotifier?.loadRewardedAd(ref: ref); // Pass ref to ensure username is loaded from secure storage
      _startCooldownTimerIfNeeded();
      setState(() {
        _isLoadingUsername = true;
      });
      await _loadWalletUsername();
      setState(() {
        _isLoadingUsername = false;
      });
      ref.read(sbdTokensProvider.notifier).fetchBalance();
      ref.read(sbdTokensProvider.notifier).fetchTransactions();
    });
  }

  Future<void> _loadWalletUsername() async {
    final storage = ref.read(secureStorageProvider);
    final storedUsername = await storage.read(key: 'user_username');
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
        setState(() {
          _cooldownRemaining = _cooldownRemaining - Duration(seconds: 1);
          if (_cooldownRemaining.isNegative || _cooldownRemaining == Duration.zero) {
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
    _confettiController.dispose();
    _coinBounceController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _watchAd() async {
    if (_adNotifier?.isRewardedAdReady != true) {
      _showAdNotReadyDialog();
      return;
    }

    // Show rewarded ad
    await _adNotifier?.showRewardedAd(
      onUserEarnedReward: (_) {}, // No-op, SSV handles reward
      onAdClosed: () async {
        await _adNotifier?.loadRewardedAd(ref: ref); // Pass ref to reload with username
      },
      onRewardCallback: (username) async {
        _handleAdReward();
      },
      ref: ref,
    );
  }

  void _handleAdReward() async {
    setState(() {
      _showRewardSuccess = true;
    });
    // Instead of addTokens, just refresh the balance and transactions
    await ref.read(sbdTokensProvider.notifier).fetchBalance();
    await ref.read(sbdTokensProvider.notifier).fetchTransactions(); // Refresh transactions after reward
    _startCooldownTimerIfNeeded();
    _confettiController.forward();
    _coinBounceController.forward();
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
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.08),
                      blurRadius: 12,
                      offset: Offset(0, 4),
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
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan this QR to receive tokens to your wallet username.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                    controller: MobileScannerController(formats: [BarcodeFormat.qrCode]),
                    fit: BoxFit.cover,
                    onDetect: (capture) {
                      final barcode = capture.barcodes.first;
                      final String? code = barcode.rawValue;
                      if (code != null && code.length <= 50 && RegExp(r'^[a-zA-Z0-9._-]{1,50} **$').hasMatch(code)) {
                        Navigator.of(context).pop();
                        _recipientController.text = code;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Username scanned: ' + code)),
                        );
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
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cancel'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final sbdState = ref.watch(sbdTokensProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'SBD Wallet',
        showCurrency: false,
        showHamburger: false,
      ),
      body: Stack(
        children: [
          if (sbdState.isLoading)
            const Center(child: CircularProgressIndicator()),
          if (sbdState.error != null)
            Center(child: Text('Error: ' + sbdState.error!)),
          if (!sbdState.isLoading && sbdState.error == null)
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 32 + MediaQuery.of(context).padding.bottom), // Add extra bottom padding for nav bar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wallet Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    height: 120,
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage('assets/wallet_card_bg.jpg'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(18),
                                  child: Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: theme.primaryColor,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Balance', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                                const SizedBox(height: 6),
                                Text(
                                  sbdState.balance?.toString() ?? '--',
                                  style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                Text('Available Balance', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Send Tokens
                    Text('Send Tokens', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            maxLength: 50,
                            controller: _recipientController,
                            decoration: InputDecoration(
                              hintText: 'Recipient Username',
                              filled: true,
                              fillColor: theme.cardColor,
                              hintStyle: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: Icon(Icons.person_outline, color: theme.primaryColor),
                              counterText: '',
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            decoration: InputDecoration(
                              hintText: 'Amount',
                              filled: true,
                              fillColor: theme.cardColor,
                              hintStyle: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: Icon(Icons.sports_esports, color: theme.primaryColor),
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSending
                                ? null
                                : () async {
                                    final toUser = _recipientController.text.trim();
                                    final amountText = _amountController.text.trim();
                                    if (toUser.isEmpty || amountText.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Please enter a recipient and amount.')),
                                      );
                                      return;
                                    }
                                    final amount = int.tryParse(amountText);
                                    if (amount == null || amount <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Please enter a valid amount greater than 0.')),
                                      );
                                      return;
                                    }
                                    if (sbdState.balance != null && amount > (sbdState.balance ?? 0)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('You cannot send more than your available balance.')),
                                      );
                                      return;
                                    }
                                    final didAuth = await _authenticateForSend();
                                    if (!didAuth) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Authentication failed. Cannot send tokens.')),
                                      );
                                      return;
                                    }
                                    setState(() => _isSending = true);
                                    final success = await ref.read(sbdTokensProvider.notifier).sendTokens(toUser: toUser, amount: amount);
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
                                            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                            child: Center(
                                              child: Container(
                                                margin: const EdgeInsets.all(0),
                                                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                                                decoration: BoxDecoration(
                                                  color: theme.cardColor,
                                                  borderRadius: BorderRadius.circular(24),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: theme.shadowColor.withOpacity(0.08),
                                                      blurRadius: 16,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.check_circle, color: theme.primaryColor, size: 48),
                                                    const SizedBox(height: 18),
                                                    Text('Sent!', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                                    const SizedBox(height: 10),
                                                    Text('You sent $amount SBD to $toUser.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                                                    const SizedBox(height: 28),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: theme.primaryColor,
                                                          foregroundColor: theme.colorScheme.onPrimary,
                                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                        ),
                                                        onPressed: () {
                                                          Navigator.of(context).pop(); // Just close dialog, no loading
                                                        },
                                                        child: const Text('Go to Wallet'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                      // After dialog closes, refresh balance and transactions (no loading spinner)
                                      await ref.read(sbdTokensProvider.notifier).fetchBalance();
                                      await ref.read(sbdTokensProvider.notifier).fetchTransactions();
                                    } else {
                                      final err = ref.read(sbdTokensProvider).error;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${err ?? 'Unknown error'}')));
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: theme.primaryColor,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSending
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                                    ),
                                  )
                                : Text('Send', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _showQrScanDialog,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: theme.cardColor,
                              foregroundColor: theme.colorScheme.onSurface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Scan QR', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    // Receive Tokens
                    Text('Receive Tokens', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.person, color: theme.colorScheme.onSurface, size: 32),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isLoadingUsername)
                                  SizedBox(
                                    height: 18,
                                    width: 80,
                                    child: Container(
                                      color: theme.dividerColor.withOpacity(0.2),
                                    ),
                                  )
                                else
                                  Text(_walletUsername, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text('Your Wallet Username', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showQrCodeDialog(_walletUsername);
                            },
                            icon: Icon(Icons.qr_code, color: theme.colorScheme.onPrimary),
                            label: Text('My QR', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              backgroundColor: theme.primaryColor,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Earn Section
                    Text('Earn', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Watch Ad to Earn +10 SBD',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Earn rewards by watching short ads',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: 120,
                                  child: ElevatedButton.icon(
                                    onPressed: _watchAd,
                                    icon: Icon(Icons.play_arrow, color: theme.colorScheme.onPrimary, size: 18),
                                    label: Text('Watch Ad', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimary, fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                      backgroundColor: theme.primaryColor,
                                      foregroundColor: theme.colorScheme.onPrimary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      minimumSize: const Size(0, 32),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 2,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                height: 120,
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage('assets/earn_section_bg.jpg'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Transactions List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Transactions', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        if (sbdState.transactions != null && sbdState.transactions!.length > 0)
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const TransactionsScreenV1()),
                              );
                            },
                            child: Text('See more', style: theme.textTheme.labelLarge?.copyWith(color: theme.primaryColor)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (sbdState.transactions != null && sbdState.transactions!.isNotEmpty)
                      ...sbdState.transactions!.take(5).map((tx) {
                        return MinimalTransactionCard(
                          tx: tx,
                          theme: theme,
                          onTap: () async {
                            await showDialog(
                              context: context,
                              builder: (context) => TransactionDetailsDialog(
                                tx: tx,
                                theme: theme,
                                onNoteSaved: (note) async {
                                  setState(() {
                                    tx['note'] = note;
                                  });
                                  if (tx['transaction_id'] != null && note.isNotEmpty) {
                                    await ref.read(sbdTokensProvider.notifier).updateTransactionNote(
                                      transactionId: tx['transaction_id'],
                                      note: note,
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        );
                      }).toList(),
                    if (sbdState.transactions != null && sbdState.transactions!.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('No transactions found.', style: theme.textTheme.bodyMedium),
                      ),
                  ],
                ),
              ),
            ),
          if (_showRewardSuccess) _buildRewardOverlay(theme, sbdState),
        ],
      ),
    );
  }

  Widget _buildRewardOverlay(ThemeData theme, dynamic sbdState) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(32),
          padding: EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.18),
                blurRadius: 32,
                offset: Offset(0, 12),
              ),
            ],
            border: Border.all(color: theme.primaryColor.withOpacity(0.18), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primaryColor.withOpacity(0.18), theme.primaryColor.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(24),
                child: AnimatedBuilder(
                  animation: _coinBounceAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _coinBounceAnimation.value,
                      child: Icon(
                        Icons.emoji_events_rounded,
                        color: theme.primaryColor,
                        size: 64,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Congratulations!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                  fontSize: 26,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                "You've Earned +10 SBD!",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'via AdMob',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _watchAd,
                      icon: Icon(Icons.replay, color: theme.primaryColor),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.primaryColor, width: 1.5),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      label: Text(
                        'Watch Again',
                        style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showRewardSuccess = false;
                        });
                      },
                      icon: Icon(Icons.check_circle, color: theme.colorScheme.onPrimary),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      label: Text('Continue', style: TextStyle(fontWeight: FontWeight.w600)),
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
}

class TransactionDetailsDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> tx;
  final ThemeData theme;
  final void Function(String note) onNoteSaved;
  const TransactionDetailsDialog({required this.tx, required this.theme, required this.onNoteSaved});

  @override
  ConsumerState<TransactionDetailsDialog> createState() => TransactionDetailsDialogState();
}

class TransactionDetailsDialogState extends ConsumerState<TransactionDetailsDialog> {
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
      backgroundColor: Colors.transparent, // Make dialog background transparent for card effect
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
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
            border: Border.all(color: theme.primaryColor.withOpacity(0.13), width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isSend ? Colors.redAccent.withOpacity(0.12) : Colors.green.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        isSend ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: isSend ? Colors.redAccent : Colors.green,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      isSend ? 'Sent' : 'Received',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, color: theme.primaryColor, size: 22),
                    const SizedBox(width: 8),
                    Text('Amount:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text('$amount SBD', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_outline, color: theme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(isSend ? 'To:' : 'From:', style: theme.textTheme.bodyMedium),
                    const SizedBox(width: 6),
                    Text(otherUser, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.access_time, color: theme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text('Time:', style: theme.textTheme.bodyMedium),
                    const SizedBox(width: 6),
                    Text(formattedTimestamp, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.numbers, color: theme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text('Transaction ID:', style: theme.textTheme.bodyMedium),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(transactionId, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor), overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, size: 18, color: theme.primaryColor),
                      tooltip: 'Copy Transaction ID',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: transactionId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Transaction ID copied!'), duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                // Note box with improved structure
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.primaryColor.withOpacity(0.18)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Note', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          if (!_isEditing)
                            IconButton(
                              icon: Icon(Icons.edit, color: theme.primaryColor, size: 20),
                              tooltip: 'Edit Note',
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _isEditing
                          ? Column(
                              children: [
                                TextField(
                                  controller: _noteController,
                                  decoration: InputDecoration(
                                    hintText: 'Add a note to this transaction',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  ),
                                  maxLines: 2,
                                  autofocus: true,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          widget.onNoteSaved(_noteController.text.trim());
                                          setState(() {
                                            _isEditing = false;
                                            _originalNote = _noteController.text.trim();
                                          });
                                          Navigator.of(context).pop();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.primaryColor,
                                          foregroundColor: theme.colorScheme.onPrimary,
                                        ),
                                        child: const Text('Save'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            _noteController.text = _originalNote ?? '';
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
                          : Text(
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
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}