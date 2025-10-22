import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/profiles_provider.dart';

class ProfileSwitcherSheet extends ConsumerWidget {
  const ProfileSwitcherSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profilesProvider);
    final notifier = ref.read(profilesProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Switch profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...state.profiles.map((p) {
                final isCurrent = state.current?.id == p.id;
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(p.displayName[0].toUpperCase()),
                  ),
                  title: Text(p.displayName),
                  subtitle: p.email != null ? Text(p.email!) : null,
                  trailing: isCurrent
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: isCurrent
                      ? null
                      : () async {
                          await notifier.switchTo(p.id);
                          Navigator.of(context).pop();
                        },
                );
              }).toList(),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Close the sheet first, then navigate to the main Auth screen
                        Navigator.of(context).pop();
                        // Give the pop animation a tick to complete before pushing
                        await Future.delayed(const Duration(milliseconds: 100));
                        Navigator.of(context).pushNamed('/auth/v1');
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add profile'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Logout
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text(
                              'Are you sure you want to logout?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await notifier.logout();
                        }
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
