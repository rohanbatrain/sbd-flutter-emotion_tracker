import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/sbd_tokens_provider.dart';
import 'package:emotion_tracker/screens/currency/variant2.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showHamburger;
  final bool showCurrency;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.showHamburger = true,
    this.showCurrency = true,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final sbdState = ref.watch(sbdTokensProvider);

    return AppBar(
      title: Text(title, overflow: TextOverflow.ellipsis, maxLines: 1),
      leading: showHamburger
          ? Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : leading,
      actions: [
        if (showCurrency)
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => CurrencyScreenV2()),
              );
            },
            child: Container(
              margin: EdgeInsets.only(right: 16),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.onPrimary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.psychology,
                    color: theme.colorScheme.onPrimary,
                    size: 18,
                  ),
                  SizedBox(width: 4),
                  if (sbdState.isLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  else if (sbdState.error != null)
                    Icon(Icons.error, color: Colors.red, size: 18)
                  else
                    Text(
                      _formatCurrency(sbdState.balance),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ...?actions,
      ],
      backgroundColor: theme.primaryColor,
      foregroundColor: theme.colorScheme.onPrimary,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _formatCurrency(num? value) {
    if (value == null) return '--';
    if (value >= 1000000) {
      return (value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1) +
          'M';
    } else if (value >= 1000) {
      return (value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1) + 'k';
    } else {
      return value.toString();
    }
  }
}
