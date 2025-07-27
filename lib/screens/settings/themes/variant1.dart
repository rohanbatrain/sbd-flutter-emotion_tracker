import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/providers/theme_unlock_provider.dart';
import 'package:emotion_tracker/screens/shop/variant1/variant1.dart';
import 'package:emotion_tracker/core/session_manager.dart';
import 'package:emotion_tracker/core/global_error_handler.dart';
import 'package:emotion_tracker/core/error_state.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';

class ThemeSelectionScreenV1 extends ConsumerStatefulWidget {
  const ThemeSelectionScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<ThemeSelectionScreenV1> createState() => _ThemeSelectionScreenV1State();
}

class _ThemeSelectionScreenV1State extends ConsumerState<ThemeSelectionScreenV1> {
  int toggleState = 0; // 0 = Light, 1 = Dark

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentThemeKey = ref.read(themeProvider);
    if (AppThemes.darkThemeKeys.contains(currentThemeKey)) {
      if (toggleState != 1 && mounted) setState(() => toggleState = 1);
    } else if (AppThemes.lightThemeKeys.contains(currentThemeKey)) {
      if (toggleState != 0 && mounted) setState(() => toggleState = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final currentThemeKey = ref.watch(themeProvider);
    final isLight = toggleState == 0;
    final themeKeys = isLight ? AppThemes.lightThemeKeys : AppThemes.darkThemeKeys;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Theme Selection',
        showHamburger: false,
        showCurrency: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh themes',
            onPressed: () {
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            // Toggle for Light/Dark with swipe support
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < 0 && toggleState == 0) {
                    // Swipe left: Light -> Dark
                    if (mounted) setState(() => toggleState = 1);
                  } else if (details.primaryVelocity! > 0 && toggleState == 1) {
                    // Swipe right: Dark -> Light
                    if (mounted) setState(() => toggleState = 0);
                  }
                }
              },
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ThemeToggleButton(
                        label: 'Light',
                        selected: isLight,
                        onTap: () {
                          if (mounted) setState(() => toggleState = 0);
                        },
                        icon: Icons.wb_sunny_outlined,
                      ),
                      _ThemeToggleButton(
                        label: 'Dark',
                        selected: !isLight,
                        onTap: () {
                          if (mounted) setState(() => toggleState = 1);
                        },
                        icon: Icons.nightlight_round,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Choose your preferred theme:',
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: 16),
            // Swipe support for theme grid as well
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < 0 && toggleState == 0) {
                      if (mounted) setState(() => toggleState = 1);
                    } else if (details.primaryVelocity! > 0 && toggleState == 1) {
                      if (mounted) setState(() => toggleState = 0);
                    }
                  }
                },
                child: FutureBuilder<Set<String>>(
                  future: ref.read(themeUnlockProvider).getMergedUnlockedThemes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingStateWidget(message: 'Loading available themes...');
                    }
                    if (snapshot.hasError) {
                      final errorState = GlobalErrorHandler.processError(snapshot.error);
                      if (errorState.autoRedirect && errorState.type == ErrorType.unauthorized) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          SessionManager.redirectToLogin(context, message: errorState.message);
                        });
                        return const LoadingStateWidget(message: 'Session expired. Redirecting to login...');
                      }
                      return ErrorStateWidget(
                        error: snapshot.error,
                        onRetry: () => setState(() {}),
                        customMessage: errorState.message,
                      );
                    }
                    final unlockedThemes = snapshot.data ?? {};
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: themeKeys.length,
                      itemBuilder: (context, index) {
                        final themeKey = themeKeys[index];
                        final themeName = AppThemes.themeNames[themeKey];
                        final themeData = AppThemes.allThemes[themeKey];
                        if (themeName == null || themeData == null) {
                          return Container(
                            alignment: Alignment.center,
                            child: Text(
                              'Theme config error: $themeKey',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        final isSelected = currentThemeKey == themeKey;
                        final isUnlocked = themeKey == 'lightTheme' || themeKey == 'darkTheme' || unlockedThemes.contains(themeKey);
                        return GestureDetector(
                          onTap: () async {
                            if (!isUnlocked) {
                              // Use provider's ad unlock logic with callback to refresh UI only after ad is finished
                              final themeUnlockService = ref.read(themeUnlockProvider);
                              await themeUnlockService.showThemeUnlockAd(context, themeKey, onThemeUnlocked: () {
                                if (mounted) setState(() {});
                              });
                              return;
                            }
                            ref.read(themeProvider.notifier).setTheme(themeKey);
                          },
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? themeData.primaryColor : Colors.grey.withOpacity(0.3),
                                    width: isSelected ? 3 : 1,
                                  ),
                                  color: themeData.primaryColor.withOpacity(0.1),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: themeData.primaryColor,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        themeName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: themeData.primaryColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!isUnlocked)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Icon(Icons.lock, color: themeData.primaryColor, size: 18),
                                ),
                              if (isSelected)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Icon(
                                    Icons.check_circle,
                                    color: themeData.primaryColor,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 24),
            SafeArea(
              top: false,
              left: false,
              right: false,
              minimum: EdgeInsets.zero,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ShopScreenV1()),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.18),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.storefront, color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'View Shop',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// Beautiful toggle button widget
class _ThemeToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  const _ThemeToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : Theme.of(context).iconTheme.color),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
