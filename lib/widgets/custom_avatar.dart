import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

// --- Data Models ---
enum AvatarType { static, animated }

class Avatar {
  final String id;
  final String name;
  final AvatarType type;
  final IconData? icon; // For static
  final String? animationAsset; // For animated
  final bool isPremium;
  final int price; // SBD Tokens

  const Avatar({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.animationAsset,
    this.isPremium = false,
    this.price = 0,
  }) : assert(
          (type == AvatarType.static && icon != null) ||
              (type == AvatarType.animated && animationAsset != null),
          'Static avatars must have an icon, and animated avatars must have an animationAsset.',
        );
}

// --- Avatar Data ---
final List<Avatar> staticAvatars = [
  const Avatar(id: 'person', name: 'Person', icon: Icons.person, type: AvatarType.static, price: 0),
  const Avatar(id: 'cat', name: 'Cat', icon: Icons.pets, type: AvatarType.static, price: 50),
  const Avatar(id: 'robot', name: 'Robot', icon: Icons.android, type: AvatarType.static, price: 50),
  const Avatar(id: 'dog', name: 'Dog', icon: Icons.pets, type: AvatarType.static, price: 50),
  const Avatar(id: 'star', name: 'Star', icon: Icons.star, type: AvatarType.static, price: 100),
  const Avatar(id: 'face', name: 'Smiley', icon: Icons.sentiment_satisfied, type: AvatarType.static, price: 100),
  const Avatar(id: 'flower', name: 'Flower', icon: Icons.local_florist, type: AvatarType.static, price: 100),
  const Avatar(id: 'game', name: 'Controller', icon: Icons.gamepad, type: AvatarType.static, price: 150),
  const Avatar(id: 'headset', name: 'Music', icon: Icons.headset, type: AvatarType.static, price: 150),
  const Avatar(id: 'cake', name: 'Cake', icon: Icons.cake, type: AvatarType.static, price: 150),
  const Avatar(id: 'camera', name: 'Camera', icon: Icons.camera_alt, type: AvatarType.static, price: 150),
  const Avatar(id: 'car', name: 'Car', icon: Icons.directions_car, type: AvatarType.static, price: 150),
  const Avatar(id: 'book', name: 'Book', icon: Icons.book, type: AvatarType.static, price: 150),
  const Avatar(id: 'brush', name: 'Brush', icon: Icons.brush, type: AvatarType.static, price: 150),
  const Avatar(id: 'build', name: 'Build', icon: Icons.build, type: AvatarType.static, price: 150),
  const Avatar(id: 'cloud', name: 'Cloud', icon: Icons.cloud, type: AvatarType.static, price: 150),
  const Avatar(id: 'code', name: 'Code', icon: Icons.code, type: AvatarType.static, price: 200),
  const Avatar(id: 'color', name: 'Palette', icon: Icons.color_lens, type: AvatarType.static, price: 200),
  const Avatar(id: 'computer', name: 'Computer', icon: Icons.computer, type: AvatarType.static, price: 200),
  const Avatar(id: 'content_cut', name: 'Scissors', icon: Icons.content_cut, type: AvatarType.static, price: 200),
  const Avatar(id: 'desktop', name: 'Desktop', icon: Icons.desktop_windows, type: AvatarType.static, price: 200),
  const Avatar(id: 'moon', name: 'Moon', icon: Icons.dark_mode, type: AvatarType.static, price: 250),
  const Avatar(id: 'eco', name: 'Leaf', icon: Icons.eco, type: AvatarType.static, price: 250),
  const Avatar(id: 'explore', name: 'Compass', icon: Icons.explore, type: AvatarType.static, price: 250),
  const Avatar(id: 'extension', name: 'Puzzle', icon: Icons.extension, type: AvatarType.static, price: 250),
  const Avatar(id: 'fastfood', name: 'Burger', icon: Icons.fastfood, type: AvatarType.static, price: 250),
  const Avatar(id: 'flag', name: 'Flag', icon: Icons.flag, type: AvatarType.static, price: 250),
  const Avatar(id: 'flare', name: 'Sparkle', icon: Icons.flare, type: AvatarType.static, price: 300),
  const Avatar(id: 'flight', name: 'Plane', icon: Icons.flight, type: AvatarType.static, price: 300),
  const Avatar(id: 'free_breakfast', name: 'Coffee', icon: Icons.free_breakfast, type: AvatarType.static, price: 300),
  const Avatar(id: 'gift', name: 'Gift', icon: Icons.card_giftcard, type: AvatarType.static, price: 300),
  const Avatar(id: 'globe', name: 'Globe', icon: Icons.public, type: AvatarType.static, price: 300),
  const Avatar(id: 'heart', name: 'Heart', icon: Icons.favorite, type: AvatarType.static, price: 350),
  const Avatar(id: 'home', name: 'Home', icon: Icons.home, type: AvatarType.static, price: 350),
  const Avatar(id: 'icecream', name: 'Ice Cream', icon: Icons.icecream, type: AvatarType.static, price: 350),
  const Avatar(id: 'key', name: 'Key', icon: Icons.vpn_key, type: AvatarType.static, price: 350),
  const Avatar(id: 'lightbulb', name: 'Idea', icon: Icons.lightbulb, type: AvatarType.static, price: 350),
  const Avatar(id: 'motorcycle', name: 'Motorcycle', icon: Icons.motorcycle, type: AvatarType.static, price: 400),
  const Avatar(id: 'movie', name: 'Movie', icon: Icons.movie, type: AvatarType.static, price: 400),
  const Avatar(id: 'music_note', name: 'Note', icon: Icons.music_note, type: AvatarType.static, price: 400),
  const Avatar(id: 'palette', name: 'Art', icon: Icons.palette, type: AvatarType.static, price: 400),
  const Avatar(id: 'pizza', name: 'Pizza', icon: Icons.local_pizza, type: AvatarType.static, price: 400),
  const Avatar(id: 'school', name: 'School', icon: Icons.school, type: AvatarType.static, price: 450),
  const Avatar(id: 'science', name: 'Science', icon: Icons.science, type: AvatarType.static, price: 450),
  const Avatar(id: 'sports_esports', name: 'Esports', icon: Icons.sports_esports, type: AvatarType.static, price: 450),
  const Avatar(id: 'tree', name: 'Tree', icon: Icons.park, type: AvatarType.static, price: 450),
  const Avatar(id: 'videogame', name: 'Videogame', icon: Icons.videogame_asset, type: AvatarType.static, price: 450),
  const Avatar(id: 'watch', name: 'Watch', icon: Icons.watch, type: AvatarType.static, price: 500),
  const Avatar(id: 'water_drop', name: 'Drop', icon: Icons.water_drop, type: AvatarType.static, price: 500),
  const Avatar(id: 'whatshot', name: 'Fire', icon: Icons.whatshot, type: AvatarType.static, price: 500),
  const Avatar(id: 'joystick', name: 'Joystick', icon: Icons.gamepad_outlined, type: AvatarType.static, isPremium: true, price: 1000),
  const Avatar(id: 'sunglasses', name: 'Cool', icon: Icons.sentiment_very_satisfied, type: AvatarType.static, isPremium: true, price: 1000),
];

final List<Avatar> animatedAvatars = [
    const Avatar(
      id: 'animated_diamond',
      name: 'Diamond',
      type: AvatarType.animated,
      animationAsset: 'assets/Animation - 1749057870664.json',
      isPremium: true,
      price: 2500,
    ),
    const Avatar(
      id: 'animated_crown',
      name: 'Crown',
      type: AvatarType.animated,
      animationAsset: 'assets/Animation - 1749905705545.json',
      isPremium: true,
      price: 5000,
    ),
    const Avatar(
      id: 'animated_rocket',
      name: 'Rocket',
      type: AvatarType.animated,
      animationAsset: 'assets/Animation - 1750273841544.json',
      isPremium: true,
      price: 7500,
    ),
];

final List<Avatar> allAvatars = [...staticAvatars, ...animatedAvatars];

Avatar getAvatarById(String id) {
  return allAvatars.firstWhere((avatar) => avatar.id == id, orElse: () => staticAvatars.first);
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
    final theme = Theme.of(context);
    
    if (avatar.type == AvatarType.animated) {
      return Lottie.asset(
        avatar.animationAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    } else {
      Color color;
      if (staticIconColor != null) {
        color = staticIconColor!;
      } else {
        color = isSelected ? theme.primaryColor : theme.colorScheme.onSurface;
      }
      return Icon(avatar.icon, size: size, color: color);
    }
  }
}

class AvatarSelectionDialog extends StatelessWidget {
  final String currentAvatarId;

  const AvatarSelectionDialog({Key? key, required this.currentAvatarId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final Map<String, List<Avatar>> avatarCategories = {
      'Static': staticAvatars,
      'Animated ✨': animatedAvatars,
    };

    return AlertDialog(
      title: const Text('Choose your Avatar'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      content: Container(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: avatarCategories.keys.length,
          separatorBuilder: (context, index) => const Divider(height: 30),
          itemBuilder: (context, index) {
            final category = avatarCategories.keys.elementAt(index);
            final avatars = avatarCategories[category]!;
            
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
}
