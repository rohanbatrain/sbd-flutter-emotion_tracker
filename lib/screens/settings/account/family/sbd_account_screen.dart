import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/providers/family/family_provider.dart';
import 'package:emotion_tracker/providers/family/family_api_service.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/core/global_error_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:local_auth/local_auth.dart';
import 'package:emotion_tracker/core/session_manager.dart';
import 'package:emotion_tracker/core/exceptions.dart';
import 'package:emotion_tracker/core/error_state.dart';
import 'package:emotion_tracker/screens/settings/account/family/purchase_requests_screen.dart';
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

class SBDAccountScreen extends ConsumerStatefulWidget {
  final String familyId;

  const SBDAccountScreen({Key? key, required this.familyId}) : super(key: key);

  @override
  ConsumerState<SBDAccountScreen> createState() => _SBDAccountScreenState();
}

class _SBDAccountScreenState extends ConsumerState<SBDAccountScreen>
    with TickerProviderStateMixin {
  int _selectedTab = 0;

  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSending = false;
  ErrorState? _errorState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _refreshWalletData();
    });
  }

  Future<void> _refreshWalletData() async {
    setState(() {
      _errorState = null;
    });
    try {
      await ref
          .read(familyDetailsProvider(widget.familyId).notifier)
          .loadFamilyDetails();
      await ref
          .read(transactionsProvider(widget.familyId).notifier)
          .loadTransactions();
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
        localizedReason: 'Authenticate to send SBD tokens from family account',
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
    _recipientController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailsState = ref.watch(familyDetailsProvider(widget.familyId));
    final transactionsState = ref.watch(transactionsProvider(widget.familyId));
    final account = detailsState.sbdAccount;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: account?.displayName ?? 'Family SBD Account',
        showCurrency: false,
        showHamburger: false,
      ),
      body: _errorState != null
          ? ErrorStateWidget(
              error: _errorState!,
              onRetry: _handleRetry,
              customMessage: 'Unable to load family account data.',
            )
          : account == null
          ? const LoadingStateWidget(message: 'Loading family account...')
          : IndexedStack(
              index: _selectedTab,
              children: [
                _buildOverviewTab(theme, detailsState, transactionsState),
                _buildSendTab(theme, detailsState),
                _buildTransactionsTab(theme, transactionsState),
                _buildMembersTab(theme, detailsState),
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
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send_rounded),
            label: detailsState.family?.isAdmin ?? false ? 'Send' : 'Request',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: 'Members',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    ThemeData theme,
    FamilyDetailsState detailsState,
    TransactionsState transactionsState,
  ) {
    final account = detailsState.sbdAccount!;
    final isAdmin = detailsState.family?.isAdmin ?? false;

    return RefreshIndicator(
      onRefresh: _refreshWalletData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Balance Card (Google Pay style)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    account.isFrozen ? Colors.red.shade400 : theme.primaryColor,
                    account.isFrozen
                        ? Colors.red.shade600
                        : theme.primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (account.isFrozen ? Colors.red : theme.primaryColor)
                        .withOpacity(0.3),
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
                        account.displayName,
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
                    account.balance.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    account.isFrozen
                        ? 'Account is frozen'
                        : 'Available for use',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  if (account.isFrozen && account.freezeReason != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Reason: ${account.freezeReason}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
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
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Use a consistent size for quick-action tiles so the grid
                // looks uniform for admins and non-admins.
                Builder(
                  builder: (ctx) {
                    final double totalHorizontalPadding = 40; // parent padding
                    final double spacingBetween = 12; // Wrap spacing
                    final double screenWidth = MediaQuery.of(ctx).size.width;
                    // Aim for two tiles per row on typical phone widths.
                    final double quickActionWidth =
                        (screenWidth -
                            totalHorizontalPadding -
                            spacingBetween) /
                        2;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: quickActionWidth,
                          height: 140,
                          child: _buildQuickActionCard(
                            theme: theme,
                            icon: Icons.qr_code_rounded,
                            label: 'Family QR',
                            color: Colors.blue,
                            onTap: () => _showQrCodeDialog(
                              detailsState.family?.name ?? 'Family',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: quickActionWidth,
                          height: 140,
                          child: _buildQuickActionCard(
                            theme: theme,
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'Scan QR',
                            color: Colors.green,
                            onTap: _showQrScanDialog,
                          ),
                        ),
                        // Family Shop removed temporarily
                        // Token Requests quick action removed per request
                        if (isAdmin)
                          SizedBox(
                            width: quickActionWidth,
                            height: 140,
                            child: _buildQuickActionCard(
                              theme: theme,
                              icon: Icons.admin_panel_settings_rounded,
                              label: 'Purchase Requests',
                              color: Colors.orange,
                              onTap: () => _navigateToPurchaseRequests(
                                context,
                                widget.familyId,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Family Info Card
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
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.family_restroom_rounded,
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
                              'Family Account',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              detailsState.family?.name ?? 'Family',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'ADMIN',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                if (transactionsState.transactions.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _selectedTab = 2),
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
            if (transactionsState.transactions.isNotEmpty)
              ...transactionsState.transactions.take(3).map((tx) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildTransactionCard(tx, theme),
                );
              }).toList(),
            if (transactionsState.transactions.isEmpty)
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

  Widget _buildSendTab(ThemeData theme, FamilyDetailsState detailsState) {
    final account = detailsState.sbdAccount!;
    final isAdmin = detailsState.family?.isAdmin ?? false;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Send/Request Form Card
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
                          isAdmin
                              ? Icons.send_rounded
                              : Icons.request_page_rounded,
                          color: theme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isAdmin
                            ? 'Send from Family Account'
                            : 'Request SBD Tokens',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (isAdmin) ...[
                    // Recipient Field (Admin only)
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
                  ] else ...[
                    // Reason Field (Non-admin only)
                    Text(
                      'Reason',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText:
                            'Why do you need these tokens? (min 5 characters)',
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        counterText: '',
                        prefixIcon: Icon(
                          Icons.edit_note,
                          color: theme.primaryColor,
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
                  ],

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

                  // Balance Display
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.hintColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAdmin
                            ? '${account.displayName} balance: ${account.balance} SBD'
                            : 'Request will be reviewed by family admin',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                  if (account.isFrozen && isAdmin) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock,
                            color: Colors.red.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Account is frozen - cannot send',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isAdmin
                          ? (account.isFrozen || _isSending
                                ? null
                                : _handleSendTokens)
                          : _handleRequestTokens,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAdmin && account.isFrozen
                            ? Colors.grey
                            : theme.primaryColor,
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
                                Icon(
                                  isAdmin
                                      ? Icons.send_rounded
                                      : Icons.request_page_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isAdmin
                                      ? (account.isFrozen
                                            ? 'Account Frozen'
                                            : 'Send Tokens')
                                      : 'Request Tokens',
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
                      isAdmin
                          ? 'Family transfers require admin approval and biometric authentication'
                          : 'Token requests will be reviewed by family administrators',
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
    final detailsState = ref.read(familyDetailsProvider(widget.familyId));
    final account = detailsState.sbdAccount!;

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

    if (amount > account.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient account balance.')),
      );
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
    try {
      // Call the real family transfer API
      await ref
          .read(familyApiServiceProvider)
          .transferTokens(
            familyId: widget.familyId,
            toUserId: toUser, // This should be user ID, not username
            amount: amount,
            reason: 'Family wallet transfer from admin',
          );

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
                    'Transfer Successful!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sent $amount SBD to $toUser from ${account.displayName}.',
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

      // The user may have navigated away while the dialog was open. Guard
      // against using the BuildContext or calling setState if disposed.
      if (!mounted) return;

      _amountController.clear();
      _recipientController.clear();
      await _refreshWalletData();
      if (!mounted) return;
      setState(() => _selectedTab = 0); // Switch back to Overview tab
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}')));
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _handleRequestTokens() async {
    final amountText = _amountController.text.trim();
    final reason = _reasonController.text.trim();

    if (amountText.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amount and reason.')),
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

    if (reason.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reason must be at least 5 characters long.'),
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final success = await ref
          .read(tokenRequestsProvider(widget.familyId).notifier)
          .createRequest(amount: amount, reason: reason);

      if (!mounted) return;

      if (success) {
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
                      'Request Submitted!',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your request for $amount SBD has been submitted for admin approval.',
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

        // Guard against disposed widget after the dialog returns.
        if (!mounted) return;

        _amountController.clear();
        _reasonController.clear();
        setState(() => _selectedTab = 0); // Switch back to Overview tab
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Widget _buildTransactionsTab(
    ThemeData theme,
    TransactionsState transactionsState,
  ) {
    if (transactionsState.isLoading) {
      return LoadingStateWidget(message: 'Loading transactions...');
    }

    if (transactionsState.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(transactionsProvider(widget.familyId).notifier)
            .loadTransactions();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: transactionsState.transactions.length,
        itemBuilder: (context, index) {
          final tx = transactionsState.transactions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildTransactionCard(tx, theme),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(dynamic tx, ThemeData theme) {
    final isSend = tx.type == 'spend' || tx.type == 'send';
    final isReceive = tx.type == 'receive';
    final otherUser = isSend ? tx.to : (isReceive ? tx.from : '');
    final amount = tx.amount ?? 0;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showTransactionDetailsDialog(tx),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSend
                          ? 'Sent to ${otherUser}'
                          : 'Received from ${otherUser}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tx.description ?? tx.type.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isSend ? '-' : '+'}${amount}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSend ? Colors.red : Colors.green,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'SBD',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
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

  Widget _buildMembersTab(ThemeData theme, FamilyDetailsState detailsState) {
    final isAdmin = detailsState.family?.isAdmin ?? false;

    if (detailsState.members.isEmpty) {
      return Center(child: Text('No members found'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: detailsState.members.length,
      itemBuilder: (context, index) {
        final member = detailsState.members[index];
        final permissions = member.spendingPermissions;

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      child: Text(
                        member.displayName[0].toUpperCase(),
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            member.role.toUpperCase(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Can Spend:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    StatefulBuilder(
                      builder: (context, setLocalState) {
                        bool _isUpdating = false;
                        return Builder(
                          builder: (ctx) {
                            return AbsorbPointer(
                              absorbing: _isUpdating == true,
                              child: Row(
                                children: [
                                  Switch(
                                    // If permissions are missing, default to false so non-admin viewers
                                    // don't see an erroneously enabled control state.
                                    value: permissions?.canSpend ?? false,
                                    onChanged: isAdmin
                                        ? (value) async {
                                            // local loading flag to disable rapid toggles
                                            setLocalState(
                                              () => _isUpdating = true,
                                            );
                                            try {
                                              final result = await ref
                                                  .read(
                                                    familyDetailsProvider(
                                                      widget.familyId,
                                                    ).notifier,
                                                  )
                                                  .updateSpendingPermissions(
                                                    userId: member.userId,
                                                    spendingLimit:
                                                        permissions
                                                            ?.spendingLimit ??
                                                        -1,
                                                    canSpend: value,
                                                  );

                                              if (result == null) {
                                                final errorState =
                                                    GlobalErrorHandler.processError(
                                                      Exception(
                                                        'Failed to update permissions',
                                                      ),
                                                    );
                                                if (mounted) {
                                                  GlobalErrorHandler.showErrorSnackbar(
                                                    context,
                                                    errorState.message,
                                                    errorState.type,
                                                  );
                                                }
                                              } else {
                                                // refresh to ensure members list is up-to-date
                                                await ref
                                                    .read(
                                                      familyDetailsProvider(
                                                        widget.familyId,
                                                      ).notifier,
                                                    )
                                                    .loadFamilyDetails();
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        result['message'] ??
                                                            'Permissions updated',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            } catch (e) {
                                              final errorState =
                                                  GlobalErrorHandler.processError(
                                                    e,
                                                  );
                                              GlobalErrorHandler.showErrorSnackbar(
                                                context,
                                                errorState.message,
                                                errorState.type,
                                              );
                                            } finally {
                                              setLocalState(
                                                () => _isUpdating = false,
                                              );
                                            }
                                          }
                                        : null,
                                  ),
                                  if (_isUpdating) ...[
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spending Limit:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Row(
                      children: [
                        Text(
                          // If permissions object is missing, be explicit instead of showing defaults.
                          permissions == null
                              ? 'Not available'
                              : (permissions.spendingLimit == -1
                                    ? 'Unlimited'
                                    : '${permissions.spendingLimit} SBD'),
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isAdmin)
                          IconButton(
                            tooltip: 'Edit spending limit',
                            icon: Icon(
                              Icons.edit,
                              size: 18,
                              color: theme.primaryColor,
                            ),
                            onPressed: () async {
                              final currentLimit =
                                  permissions?.spendingLimit ?? -1;

                              await showDialog<void>(
                                context: context,
                                builder: (dialogContext) {
                                  final TextEditingController _limitController =
                                      TextEditingController(
                                        text: currentLimit == -1
                                            ? ''
                                            : currentLimit.toString(),
                                      );
                                  bool _isUnlimited = currentLimit == -1;
                                  bool _isSaving = false;

                                  return StatefulBuilder(
                                    builder: (context, setState) => Dialog(
                                      backgroundColor: theme.cardColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Edit Spending Limit',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Checkbox(
                                                  value: _isUnlimited,
                                                  onChanged: (v) => setState(
                                                    () => _isUnlimited =
                                                        v ?? false,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Expanded(
                                                  child: Text('Unlimited'),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _limitController,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Spending limit (SBD)',
                                                hintText: 'Enter integer value',
                                              ),
                                              enabled: !_isUnlimited,
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: _isSaving
                                                      ? null
                                                      : () => Navigator.of(
                                                          dialogContext,
                                                        ).pop(),
                                                  child: const Text('Cancel'),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed: _isSaving
                                                      ? null
                                                      : () async {
                                                          // Validate input
                                                          int newLimit;
                                                          if (_isUnlimited) {
                                                            newLimit = -1;
                                                          } else {
                                                            final text =
                                                                _limitController
                                                                    .text
                                                                    .trim();
                                                            if (text.isEmpty) {
                                                              final errorState =
                                                                  GlobalErrorHandler.processError(
                                                                    Exception(
                                                                      'Please enter a spending limit or select Unlimited',
                                                                    ),
                                                                  );
                                                              GlobalErrorHandler.showErrorSnackbar(
                                                                context,
                                                                errorState
                                                                    .message,
                                                                errorState.type,
                                                              );
                                                              return;
                                                            }
                                                            try {
                                                              newLimit =
                                                                  int.parse(
                                                                    text,
                                                                  );
                                                            } catch (e) {
                                                              final errorState =
                                                                  GlobalErrorHandler.processError(
                                                                    Exception(
                                                                      'Invalid number',
                                                                    ),
                                                                  );
                                                              GlobalErrorHandler.showErrorSnackbar(
                                                                context,
                                                                errorState
                                                                    .message,
                                                                errorState.type,
                                                              );
                                                              return;
                                                            }
                                                            if (newLimit < 0) {
                                                              final errorState =
                                                                  GlobalErrorHandler.processError(
                                                                    Exception(
                                                                      'spending_limit must be >= -1',
                                                                    ),
                                                                  );
                                                              GlobalErrorHandler.showErrorSnackbar(
                                                                context,
                                                                errorState
                                                                    .message,
                                                                errorState.type,
                                                              );
                                                              return;
                                                            }
                                                          }

                                                          setState(
                                                            () => _isSaving =
                                                                true,
                                                          );
                                                          try {
                                                            final result = await ref
                                                                .read(
                                                                  familyDetailsProvider(
                                                                    widget
                                                                        .familyId,
                                                                  ).notifier,
                                                                )
                                                                .updateSpendingPermissions(
                                                                  userId: member
                                                                      .userId,
                                                                  spendingLimit:
                                                                      newLimit,
                                                                  canSpend:
                                                                      permissions
                                                                          ?.canSpend ??
                                                                      true,
                                                                );

                                                            if (result !=
                                                                null) {
                                                              // Refresh and close dialog
                                                              await ref
                                                                  .read(
                                                                    familyDetailsProvider(
                                                                      widget
                                                                          .familyId,
                                                                    ).notifier,
                                                                  )
                                                                  .loadFamilyDetails();
                                                              // Close the dialog (use dialogContext). Showing a
                                                              // SnackBar uses the parent widget context so guard
                                                              // with mounted.
                                                              try {
                                                                Navigator.of(
                                                                  dialogContext,
                                                                ).pop();
                                                              } catch (_) {}
                                                              if (mounted) {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      result['message'] ??
                                                                          'Spending limit updated',
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            } else {
                                                              final errorState =
                                                                  GlobalErrorHandler.processError(
                                                                    Exception(
                                                                      'Failed to update spending limit',
                                                                    ),
                                                                  );
                                                              if (mounted) {
                                                                GlobalErrorHandler.showErrorSnackbar(
                                                                  context,
                                                                  errorState
                                                                      .message,
                                                                  errorState
                                                                      .type,
                                                                );
                                                              }
                                                            }
                                                          } catch (e) {
                                                            final errorState =
                                                                GlobalErrorHandler.processError(
                                                                  e,
                                                                );
                                                            GlobalErrorHandler.showErrorSnackbar(
                                                              context,
                                                              errorState
                                                                  .message,
                                                              errorState.type,
                                                            );
                                                          } finally {
                                                            setState(
                                                              () => _isSaving =
                                                                  false,
                                                            );
                                                          }
                                                        },
                                                  child: _isSaving
                                                      ? SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                              ),
                                                        )
                                                      : const Text('Save'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // QR Code Dialog
  void _showQrCodeDialog(String familyName) {
    final theme = Theme.of(context);
    final account = ref.read(familyDetailsProvider(widget.familyId)).sbdAccount;
    if (account == null) return;

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
                'Family QR Code',
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
                  data: 'sbd:${account.qrUsername}',
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                account.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan to send tokens to this family account',
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
    final theme = Theme.of(context);
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
                      if (code != null) {
                        String username = code;
                        // Handle different QR formats
                        if (code.startsWith('sbd:')) {
                          username = code.substring(4); // Remove 'sbd:' prefix
                        } else if (code.startsWith('family:')) {
                          username = code.substring(
                            7,
                          ); // Remove 'family:' prefix for backward compatibility
                        }

                        if (username.length <= 50 &&
                            RegExp(
                              r'^[a-zA-Z0-9._-]{1,50}$',
                            ).hasMatch(username)) {
                          // Avoid using context if widget was disposed or dialog closed
                          if (!mounted) return;
                          try {
                            Navigator.of(context).pop();
                          } catch (_) {}
                          _recipientController.text = username;
                          if (mounted) {
                            try {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Username scanned: $username'),
                                ),
                              );
                            } catch (_) {}
                          }
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

  void _showTransactionDetailsDialog(dynamic tx) {
    final theme = Theme.of(context);
    final isSend = tx.type == 'spend' || tx.type == 'send';
    final isReceive = tx.type == 'receive';
    final otherUser = isSend ? tx.to : (isReceive ? tx.from : '');
    final amount = tx.amount ?? 0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                  value: formatTransactionTimestamp(
                    tx.timestamp ?? '',
                    'IST',
                  ), // TODO: Get user timezone
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
      ),
    );
  }

  // Family shop navigation removed as the quick action has been hidden.

  void _navigateToPurchaseRequests(BuildContext context, String familyId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PurchaseRequestsScreen(familyId: familyId),
      ),
    );
  }

  // Token requests navigation removed as quick action is hidden.

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
