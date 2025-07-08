import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/avatar_unlock_provider.dart';

// --- Data Models ---
enum AvatarType { static, animated }

class Avatar {
  final String id;
  final String name;
  final AvatarType type;
  final String? imageAsset; // For static
  final String? animationAsset; // For animated
  final int price; // SBD Tokens
  final String? rewardedAdId;

  const Avatar({
    required this.id,
    required this.name,
    required this.type,
    this.imageAsset,
    this.animationAsset,
    this.price = 0,
    this.rewardedAdId,
  }) : assert(
          (type == AvatarType.static && imageAsset != null) ||
              (type == AvatarType.animated && animationAsset != null),
          'Static avatars must have an imageAsset, and animated avatars must have an animationAsset.',
        );
}

// --- Avatar Data ---
final List<Avatar> catAvatars = [
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-1',
    name: 'Cat 1',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-1.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/2123748182',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-2',
    name: 'Cat 2',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-2.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/1576953272',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-3',
    name: 'Cat 3',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-3.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/4369286503',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-4',
    name: 'Cat 4',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-4.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/3495188531',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-5',
    name: 'Cat 5',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-5.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/7198344419',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-6',
    name: 'Cat 6',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-6.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/5027762054',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-7',
    name: 'Cat 7',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-7.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/6637708269',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-8',
    name: 'Cat 8',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-8.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/5324626590',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-9',
    name: 'Cat 9',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-9.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/1743123168',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-10',
    name: 'Cat 10',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-10.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/2698463259',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-11',
    name: 'Cat 11',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-11.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/2401598712',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-12',
    name: 'Cat 12',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-12.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/9430041494',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-13',
    name: 'Cat 13',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-13.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/3395116186',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-14',
    name: 'Cat 14',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-14.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/5885262744',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-15',
    name: 'Cat 15',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-15.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/4516626162',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-16',
    name: 'Cat 16',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-16.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/3203544498',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-17',
    name: 'Cat 17',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-17.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/4728379153',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-18',
    name: 'Cat 18',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-18.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/3750339404',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-19',
    name: 'Cat 19',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-19.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/5793763409',
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-cat-20',
    name: 'Cat 20',
    type: AvatarType.static,
    imageAsset: 'assets/cats/cat-20.png',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/3962092397',
  ),
];

final List<String> catsCategoryKeys = catAvatars.map((e) => e.id).toList();

final List<Avatar> dogAvatars = [
  const Avatar(
    id: 'emotion_tracker-static-avatar-dog-1',
    name: 'Dog 1',
    type: AvatarType.static,
    imageAsset: 'assets/dogs/dog-1.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-dog-2',
    name: 'Dog 2',
    type: AvatarType.static,
    imageAsset: 'assets/dogs/dog-2.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-dog-3',
    name: 'Dog 3',
    type: AvatarType.static,
    imageAsset: 'assets/dogs/dog-3.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-dog-4',
    name: 'Dog 4',
    type: AvatarType.static,
    imageAsset: 'assets/dogs/dog-4.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-dog-5',
    name: 'Dog 5',
    type: AvatarType.static,
    imageAsset: 'assets/dogs/dog-5.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-dog-6',
    name: 'Dog 6',
    type: AvatarType.static,
    imageAsset: 'assets/dogs/dog-6.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-dog-7',
    name: 'Dog 7',
    type: AvatarType.static,
    imageAsset: 'assets/dogs/dog-7.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-dog-8',
    name: 'Dog 8',
    type: AvatarType.static,
    imageAsset: 'assets/dogs/dog-8.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-dog-9',
    name: 'Dog 9',
    type: AvatarType.static,
    imageAsset: 'assets/dogs/dog-9.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-dog-10',
    name: 'Dog 10',
    type: AvatarType.static,
    imageAsset: 'assets/dogs/dog-10.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-dog-11',
    name: 'Dog 11',
    type: AvatarType.static,
    imageAsset: 'assets/dogs/dog-11.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-dog-12',
    name: 'Dog 12',
    type: AvatarType.static,
    imageAsset: 'assets/dogs/dog-12.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-dog-13',
    name: 'Dog 13',
    type: AvatarType.static,
    imageAsset: 'assets/dogs/dog-13.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-dog-14',
    name: 'Dog 14',
    type: AvatarType.static,
    imageAsset: 'assets/dogs/dog-14.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-dog-15',
    name: 'Dog 15',
    type: AvatarType.static,
    imageAsset: 'assets/dogs/dog-15.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-dog-16',
    name: 'Dog 16',
    type: AvatarType.static,
    imageAsset: 'assets/dogs/dog-16.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-dog-17',
    name: 'Dog 17',
    type: AvatarType.static,
    imageAsset: 'assets/dogs/dog-17.png',
    price: 100,
  ),
];

final List<Avatar> pandaAvatars = [
  const Avatar(
    id: 'emotion_tracker-static-avatar-panda-1',
    name: 'Panda 1',
    type: AvatarType.static,
    imageAsset: 'assets/pandas/panda-1.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-panda-2',
    name: 'Panda 2',
    type: AvatarType.static,
    imageAsset: 'assets/pandas/panda-2.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-panda-3',
    name: 'Panda 3',
    type: AvatarType.static,
    imageAsset: 'assets/pandas/panda-3.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-panda-4',
    name: 'Panda 4',
    type: AvatarType.static,
    imageAsset: 'assets/pandas/panda-4.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-panda-5',
    name: 'Panda 5',
    type: AvatarType.static,
    imageAsset: 'assets/pandas/panda-5.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-panda-6',
    name: 'Panda 6',
    type: AvatarType.static,
    imageAsset: 'assets/pandas/panda-6.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-panda-7',
    name: 'Panda 7',
    type: AvatarType.static,
    imageAsset: 'assets/pandas/panda-7.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-panda-8',
    name: 'Panda 8',
    type: AvatarType.static,
    imageAsset: 'assets/pandas/panda-8.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-panda-9',
    name: 'Panda 9',
    type: AvatarType.static,
    imageAsset: 'assets/pandas/panda-9.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-panda-10',
    name: 'Panda 10',
    type: AvatarType.static,
    imageAsset: 'assets/pandas/panda-10.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-panda-11',
    name: 'Panda 11',
    type: AvatarType.static,
    imageAsset: 'assets/pandas/panda-11.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-panda-12',
    name: 'Panda 12',
    type: AvatarType.static,
    imageAsset: 'assets/pandas/panda-12.png',
    price: 100,
  ),
];
final List<Avatar> peopleAvatars = [
  const Avatar(
    id: 'emotion_tracker-static-avatar-person-1',
    name: 'Person 1',
    type: AvatarType.static,
    imageAsset: 'assets/people/person-1.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-person-2',
    name: 'Person 2',
    type: AvatarType.static,
    imageAsset: 'assets/people/person-2.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-person-3',
    name: 'Person 3',
    type: AvatarType.static,
    imageAsset: 'assets/people/person-3.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-person-4',
    name: 'Person 4',
    type: AvatarType.static,
    imageAsset: 'assets/people/person-4.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-person-5',
    name: 'Person 5',
    type: AvatarType.static,
    imageAsset: 'assets/people/person-5.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-person-6',
    name: 'Person 6',
    type: AvatarType.static,
    imageAsset: 'assets/people/person-6.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-person-7',
    name: 'Person 7',
    type: AvatarType.static,
    imageAsset: 'assets/people/person-7.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-person-8',
    name: 'Person 8',
    type: AvatarType.static,
    imageAsset: 'assets/people/person-8.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-person-9',
    name: 'Person 9',
    type: AvatarType.static,
    imageAsset: 'assets/people/person-9.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-person-10',
    name: 'Person 10',
    type: AvatarType.static,
    imageAsset: 'assets/people/person-10.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-person-11',
    name: 'Person 11',
    type: AvatarType.static,
    imageAsset: 'assets/people/person-11.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-person-12',
    name: 'Person 12',
    type: AvatarType.static,
    imageAsset: 'assets/people/person-12.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-person-13',
    name: 'Person 13',
    type: AvatarType.static,
    imageAsset: 'assets/people/person-13.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-person-14',
    name: 'Person 14',
    type: AvatarType.static,
    imageAsset: 'assets/people/person-14.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-person-15',
    name: 'Person 15',
    type: AvatarType.static,
    imageAsset: 'assets/people/person-15.png',
    price: 100,
  ),
  const Avatar(
    id: 'emotion_tracker-static-avatar-person-16',
    name: 'Person 16',
    type: AvatarType.static,
    imageAsset: 'assets/people/person-16.png',
    price: 100,
  ),
];

final List<String> dogsCategoryKeys = dogAvatars.map((e) => e.id).toList();
final List<String> pandasCategoryKeys = pandaAvatars.map((e) => e.id).toList();
final List<String> peopleCategoryKeys = peopleAvatars.map((e) => e.id).toList();

final List<Avatar> animatedAvatars = [
  const Avatar(
    id: 'emotion_tracker-animated-avatar-playful_eye',
    name: 'Playful Eye',
    type: AvatarType.animated,
    animationAsset: 'assets/Animation - 1749057870664.json',
    price: 2500,
  ),
  const Avatar(
    id: 'emotion_tracker-animated-avatar-floating_brain',
    name: 'Floating Brain',
    type: AvatarType.animated,
    animationAsset: 'assets/Animation - 1749905705545.json',
    price: 5000,
  ),
];

final List<Avatar> allAvatars = [...catAvatars, ...dogAvatars, ...pandaAvatars, ...peopleAvatars, ...animatedAvatars];

Avatar getAvatarById(String id) {
  return allAvatars.firstWhere((avatar) => avatar.id == id, orElse: () => catAvatars.first);
}

// --- UI Widgets ---

class AvatarDisplay extends StatelessWidget {
  final Avatar avatar;
  final double size;
  final bool isSelected;
  final Color? staticIconColor;

  const AvatarDisplay({
    Key? key,
    required this.avatar,
    this.size = 40,
    this.isSelected = false,
    this.staticIconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (avatar.type == AvatarType.animated) {
      return Lottie.asset(
        avatar.animationAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    } else { // Static
      return Image.asset(
        avatar.imageAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
  }
}

class AvatarSelectionDialog extends ConsumerWidget {
  final String currentAvatarId;
  final Set<String>? unlockedAvatars;

  const AvatarSelectionDialog({Key? key, required this.currentAvatarId, this.unlockedAvatars}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (unlockedAvatars != null) {
      final unlocked = unlockedAvatars!;
      final Map<String, List<Avatar>> avatarCategories = {
        'Cats 🐱': catAvatars.where((a) => unlocked.contains(a.id)).toList(),
        'Dogs 🐶': dogAvatars.where((a) => unlocked.contains(a.id)).toList(),
        'Pandas 🐼': pandaAvatars.where((a) => unlocked.contains(a.id)).toList(),
        'People 👤': peopleAvatars.where((a) => unlocked.contains(a.id)).toList(),
        'Animated ✨': animatedAvatars.where((a) => unlocked.contains(a.id)).toList(),
      };
      final hasAny = avatarCategories.values.any((list) => list.isNotEmpty);
      return AlertDialog(
        title: const Text('Choose your Avatar'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
        content: Container(
          width: double.maxFinite,
          child: hasAny
              ? ListView.separated(
                  shrinkWrap: true,
                  itemCount: avatarCategories.keys.length,
                  separatorBuilder: (context, index) => const Divider(height: 30),
                  itemBuilder: (context, index) {
                    final category = avatarCategories.keys.elementAt(index);
                    final avatars = avatarCategories[category]!;
                    if (avatars.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            category,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: avatars.length,
                          itemBuilder: (context, avatarIndex) {
                            final avatar = avatars[avatarIndex];
                            final isSelected = avatar.id == currentAvatarId;
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop(avatar.id);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? theme.primaryColor.withOpacity(0.3) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? theme.primaryColor : Colors.grey.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: Tooltip(
                                  message: avatar.name,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      AvatarDisplay(avatar: avatar, isSelected: isSelected),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, size: 64, color: theme.primaryColor),
                      const SizedBox(height: 16),
                      Text('No avatars available. Using default.', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
    }
    // Fallback: show spinner if unlockedAvatars is not provided (should not happen)
    return const Center(child: CircularProgressIndicator());
  }
}
