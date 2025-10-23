import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/profiles_provider.dart';
import 'package:emotion_tracker/widgets/profile_switcher_sheet.dart';

class AccountButton extends ConsumerWidget {
  const AccountButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesState = ref.watch(profilesProvider);
    final current = profilesState.current;

    return GestureDetector(
      onTap: () async {
        // Open modal bottom sheet
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).cardColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) => ProfileSwitcherSheet(),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              child: Text(
                (current?.displayName.isNotEmpty ?? false)
                    ? current!.displayName[0].toUpperCase()
                    : '?',
              ),
            ),
            const SizedBox(width: 12),
            // Username should take remaining space and truncate if too long
            if (current != null)
              Expanded(
                child: Text(
                  current.displayName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    // Use onSurface to contrast with the card panel placed below
                    // the banner (cardColor). When AccountButton is used inside
                    // the sidebar header (primaryColor), onPrimary will still
                    // be applied by the surrounding theme for other usages.
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
