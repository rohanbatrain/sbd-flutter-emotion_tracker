import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/profiles_provider.dart';
import 'package:emotion_tracker/providers/auth_token_manager.dart';

class ProfileSwitcherSheet extends ConsumerWidget {
  final bool isFromAuthScreen;

  const ProfileSwitcherSheet({super.key, this.isFromAuthScreen = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profilesProvider);
    final notifier = ref.read(profilesProvider.notifier);
    final authTokenManager = ref.read(authTokenManagerProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Switch Profile',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: Theme.of(
                                context,
                              ).iconTheme.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Exclude any profile with displayName equal to 'You' (case-insensitive)
                      ...state.profiles
                          .where((p) => p.displayName.toLowerCase() != 'you')
                          .map((p) {
                            final isCurrent = state.current?.id == p.id;
                            final isExpired = authTokenManager.isProfileExpired(
                              p,
                            );
                            final expiresSoon =
                                p.expiresAtMs != null &&
                                (p.expiresAtMs! -
                                        DateTime.now().millisecondsSinceEpoch) <
                                    (24 * 60 * 60 * 1000); // < 24 hours

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.1)
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCurrent
                                      ? Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.3)
                                      : Theme.of(
                                          context,
                                        ).dividerColor.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: isCurrent
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.2),
                                  child: Text(
                                    p.displayName[0].toUpperCase(),
                                    style: TextStyle(
                                      color: isCurrent
                                          ? Colors.white
                                          : Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.displayName,
                                        style: TextStyle(
                                          fontWeight: isCurrent
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        margin: const EdgeInsets.only(left: 8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor.withOpacity(0.4),
                                          ),
                                        ),
                                        child: Text(
                                          'Current',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    else if (isExpired)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.warning,
                                              size: 12,
                                              color: Colors.red,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Expired',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (expiresSoon)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.orange.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              size: 12,
                                              color: Colors.orange,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Expires soon',
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: p.email != null
                                    ? Text(p.email!)
                                    : null,
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: Theme.of(
                                    context,
                                  ).iconTheme.color?.withOpacity(0.5),
                                ),
                                onTap: () async {
                                  if (isExpired) {
                                    // Try to refresh the profile first
                                    final success = await authTokenManager
                                        .refreshProfile(p.id);
                                    if (success) {
                                      // Refresh succeeded, switch to profile
                                      await notifier.switchTo(p.id);
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Switched to ${p.displayName}',
                                          ),
                                          backgroundColor: Theme.of(
                                            context,
                                          ).primaryColor,
                                        ),
                                      );
                                    } else {
                                      // Refresh failed, navigate to login
                                      Navigator.of(context).pop();
                                      await Future.delayed(
                                        const Duration(milliseconds: 100),
                                      );
                                      Navigator.of(
                                        context,
                                      ).pushNamed('/auth/v1');
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please login to refresh this profile',
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  } else {
                                    // Profile is valid, just switch
                                    final wasCurrent = isCurrent;
                                    await notifier.switchTo(p.id);

                                    if (wasCurrent) {
                                      // If we were already on this profile, check if we're on login page
                                      // and redirect to homepage
                                      if (isFromAuthScreen) {
                                        Navigator.of(
                                          context,
                                        ).pop(); // Close profile switcher
                                        await Future.delayed(
                                          const Duration(milliseconds: 100),
                                        );
                                        Navigator.of(
                                          context,
                                        ).pushReplacementNamed('/home/v1');
                                        return;
                                      }
                                    }

                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          wasCurrent
                                              ? 'Already using ${p.displayName}'
                                              : 'Switched to ${p.displayName}',
                                        ),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).primaryColor,
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          })
                          .toList(),
                      const Divider(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                // Close the sheet first, then navigate to the main Auth screen
                                Navigator.of(context).pop();
                                // Give the pop animation a tick to complete before pushing
                                await Future.delayed(
                                  const Duration(milliseconds: 100),
                                );
                                Navigator.of(context).pushNamed('/auth/v1');
                              },
                              icon: const Icon(Icons.person_add),
                              label: const Text('Add Profile'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                // Logout
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).cardColor,
                                    title: const Text('Logout'),
                                    content: const Text(
                                      'Are you sure you want to logout?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text('Logout'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await notifier.logout();
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/auth/v1',
                                    (route) => false,
                                  );
                                }
                              },
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Logout'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
