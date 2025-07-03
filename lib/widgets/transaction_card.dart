import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

String formatTransactionTimestamp(String ts, String userTz) {
  try {
    String safeTs = ts;
    if (!ts.endsWith('Z') && !RegExp(r'[+-]\d{2}:?\d{2}').hasMatch(ts)) {
      safeTs = ts + 'Z';
    }
    final utc = DateTime.parse(safeTs).toUtc();
    final tzName = userTz;
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

class MinimalTransactionCard extends ConsumerWidget {
  final Map<String, dynamic> tx;
  final ThemeData theme;
  final VoidCallback onTap;
  const MinimalTransactionCard({required this.tx, required this.theme, required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSend = tx['type'] == 'send';
    final isReceive = tx['type'] == 'receive';
    final otherUser = isSend ? tx['to'] : (isReceive ? tx['from'] : '');
    final amount = tx['amount'] ?? 0;
    final icon = isSend
        ? Icons.arrow_upward_rounded
        : isReceive
            ? Icons.arrow_downward_rounded
            : Icons.swap_horiz_rounded;
    final iconColor = isSend
        ? Colors.redAccent
        : isReceive
            ? Colors.green
            : theme.primaryColor;
    final tzString = ref.watch(timezoneProvider);
    final formattedTimestamp = formatTransactionTimestamp(tx['timestamp'] ?? '', tzString);
    return Card(
      color: theme.cardColor,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.12),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          isSend
              ? 'To $otherUser'
              : isReceive
                  ? 'From $otherUser'
                  : 'Transaction',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          (isSend ? '-' : '+') + amount.toString() + ' SBD',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSend ? Colors.redAccent : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          formattedTimestamp,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        onTap: onTap,
      ),
    );
  }
}
