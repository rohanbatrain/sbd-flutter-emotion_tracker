import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/sbd_tokens_provider.dart';
import 'package:emotion_tracker/providers/ad_provider.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';

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
    // Instead of addTokens, just refresh the balance
    await ref.read(sbdTokensProvider.notifier).fetchBalance();
    _startCooldownTimerIfNeeded();
    _confettiController.forward();
    _coinBounceController.forward();
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showRewardSuccess = false;
        });
        _confettiController.reset();
        _coinBounceController.reset();
      }
    });
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final toUser = _recipientController.text.trim();
                              final amount = int.tryParse(_amountController.text.trim()) ?? 0;
                              if (toUser.isEmpty || amount <= 0) return;
                              final success = await ref.read(sbdTokensProvider.notifier).sendTokens(toUser: toUser, amount: amount);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent $amount SBD to $toUser')));
                                _amountController.clear();
                                _recipientController.clear();
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
                            child: Text('Send', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary)),
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
                                  'Watch Ad to Earn +50 SBD',
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
                    Text('Transactions', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 16),
                    if (sbdState.transactions != null)
                      ...sbdState.transactions!.map((tx) => ListTile(
                        title: Text('To: ' + (tx['to_user'] ?? '')),
                        subtitle: Text('Amount: ${tx['amount']}'),
                        trailing: Text(tx['timestamp'] ?? ''),
                      )),
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
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _coinBounceAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _coinBounceAnimation.value,
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.psychology,
                        color: theme.primaryColor,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              Text(
                'You\'ve Earned +50 SBD!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'via AdMob',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _watchAd,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.primaryColor),
                      ),
                      child: Text(
                        'Watch Another',
                        style: TextStyle(color: theme.primaryColor),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showRewardSuccess = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      child: Text('Continue'),
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