import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/screens/auth/login/variant1.dart';
import 'package:emotion_tracker/screens/auth/register/variant1.dart';
import 'package:emotion_tracker/widgets/profile_switcher_sheet.dart';

class AuthScreenV1 extends ConsumerStatefulWidget {
  final String? connectivityIssue;

  const AuthScreenV1({Key? key, this.connectivityIssue}) : super(key: key);

  @override
  ConsumerState<AuthScreenV1> createState() => _AuthScreenV1State();
}

class _AuthScreenV1State extends ConsumerState<AuthScreenV1> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32), // Reduced from 60
            // Toggle Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
              ), // Reduced from 32.0
              child: Container(
                padding: const EdgeInsets.all(1), // Reduced from 3
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20), // Slightly reduced
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(
                        0.08,
                      ), // Slightly reduced opacity
                      blurRadius: 6, // Reduced from 8
                      spreadRadius: 0.5, // Reduced from 1
                      offset: const Offset(0, 1), // Reduced offset
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isLogin = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ), // Reduced from 12
                          decoration: BoxDecoration(
                            color: isLogin
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              18,
                            ), // Reduced from 22
                            boxShadow: isLogin
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context).primaryColor
                                          .withOpacity(0.2), // Reduced opacity
                                      blurRadius: 4, // Reduced from 6
                                      offset: const Offset(
                                        0,
                                        1,
                                      ), // Reduced offset
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            'Login',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: isLogin
                                      ? Colors.white
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isLogin = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ), // Reduced from 12
                          decoration: BoxDecoration(
                            color: !isLogin
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              18,
                            ), // Reduced from 22
                            boxShadow: !isLogin
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context).primaryColor
                                          .withOpacity(0.2), // Reduced opacity
                                      blurRadius: 4, // Reduced from 6
                                      offset: const Offset(
                                        0,
                                        1,
                                      ), // Reduced offset
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            'Signup',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: !isLogin
                                      ? Colors.white
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10), // Reduced from 24
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! < -100) {
                    // Swiped Left
                    if (isLogin) setState(() => isLogin = false);
                  } else if (details.primaryVelocity != null &&
                      details.primaryVelocity! > 100) {
                    // Swiped Right
                    if (!isLogin) setState(() => isLogin = true);
                  }
                },
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! < -300) {
                    // Swiped Up - show profile switcher
                    if (isLogin) {
                      _showProfileSwitcher();
                    }
                  }
                },
                child: isLogin
                    ? LoginScreenV1(connectivityIssue: widget.connectivityIssue)
                    : const RegisterScreenV1(),
              ),
            ),
            // Profile switcher hint (only show on login screen)
            if (isLogin) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_up,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Swipe up to switch profiles',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  void _showProfileSwitcher() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProfileSwitcherSheet(isFromAuthScreen: true),
    );
  }
}
