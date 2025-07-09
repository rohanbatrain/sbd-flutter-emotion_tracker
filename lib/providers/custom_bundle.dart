import 'package:flutter/material.dart';

// --- Data Models ---
class Bundle {
  final String id;
  final String name;
  final String description;
  final int price; // SBD Tokens
  final List<String> includedItems; // IDs of included avatars or banners

  const Bundle({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.includedItems,
  });
}

// --- Bundle Data ---
final List<Bundle> bundles = [
  const Bundle(
    id: 'emotion_tracker-avatars-cat-bundle',
    name: 'Cat Lovers Pack',
    description: 'A bundle for cat enthusiasts with a variety of adorable cat avatars.',
    price: 2000,
    includedItems: [
      'emotion_tracker-static-avatar-cat-1',
      'emotion_tracker-static-avatar-cat-2',
      'emotion_tracker-static-avatar-cat-3',
      'emotion_tracker-static-avatar-cat-4',
      'emotion_tracker-static-avatar-cat-5',
      'emotion_tracker-static-avatar-cat-6',
      'emotion_tracker-static-avatar-cat-7',
      'emotion_tracker-static-avatar-cat-8',
      'emotion_tracker-static-avatar-cat-9',
      'emotion_tracker-static-avatar-cat-10',
      'emotion_tracker-static-avatar-cat-11',
      'emotion_tracker-static-avatar-cat-12',
      'emotion_tracker-static-avatar-cat-13',
      'emotion_tracker-static-avatar-cat-14',
      'emotion_tracker-static-avatar-cat-15',
      'emotion_tracker-static-avatar-cat-16',
      'emotion_tracker-static-avatar-cat-17',
      'emotion_tracker-static-avatar-cat-18',
      'emotion_tracker-static-avatar-cat-19',
      'emotion_tracker-static-avatar-cat-20',
    ],
  ),
  const Bundle(
    id: 'emotion_tracker-avatars-dog-bundle',
    name: 'Dog Lovers Pack',
    description: 'A bundle for dog lovers featuring a selection of charming dog avatars.',
    price: 2000,
    includedItems: [
      'emotion_tracker-static-avatar-dog-1',
      'emotion_tracker-static-avatar-dog-2',
      'emotion_tracker-static-avatar-dog-3',
      'emotion_tracker-static-avatar-dog-4',
      'emotion_tracker-static-avatar-dog-5',
      'emotion_tracker-static-avatar-dog-6',
      'emotion_tracker-static-avatar-dog-7',
      'emotion_tracker-static-avatar-dog-8',
      'emotion_tracker-static-avatar-dog-9',
      'emotion_tracker-static-avatar-dog-10',
      'emotion_tracker-static-avatar-dog-11',
      'emotion_tracker-static-avatar-dog-12',
      'emotion_tracker-static-avatar-dog-13',
      'emotion_tracker-static-avatar-dog-14',
      'emotion_tracker-static-avatar-dog-15',
      'emotion_tracker-static-avatar-dog-16',
      'emotion_tracker-static-avatar-dog-17',
    ],
  ),
  const Bundle(
    id: 'emotion_tracker-avatars-panda-bundle',
    name: 'Panda Lovers Pack',
    description: 'A bundle for panda fans with a collection of delightful panda avatars.',
    price: 1500,
    includedItems: [
      'emotion_tracker-static-avatar-panda-1',
      'emotion_tracker-static-avatar-panda-2',
      'emotion_tracker-static-avatar-panda-3',
      'emotion_tracker-static-avatar-panda-4',
      'emotion_tracker-static-avatar-panda-5',
      'emotion_tracker-static-avatar-panda-6',
      'emotion_tracker-static-avatar-panda-7',
      'emotion_tracker-static-avatar-panda-8',
      'emotion_tracker-static-avatar-panda-9',
      'emotion_tracker-static-avatar-panda-10',
      'emotion_tracker-static-avatar-panda-11',
      'emotion_tracker-static-avatar-panda-12',
    ],
  ),
  const Bundle(
    id: 'emotion_tracker-avatars-people-bundle',
    name: 'People Pack',
    description: 'A bundle featuring a variety of people avatars for every mood.',
    price: 2000,
    includedItems: [
      'emotion_tracker-static-avatar-person-1',
      'emotion_tracker-static-avatar-person-2',
      'emotion_tracker-static-avatar-person-3',
      'emotion_tracker-static-avatar-person-4',
      'emotion_tracker-static-avatar-person-5',
      'emotion_tracker-static-avatar-person-6',
      'emotion_tracker-static-avatar-person-7',
      'emotion_tracker-static-avatar-person-8',
      'emotion_tracker-static-avatar-person-9',
      'emotion_tracker-static-avatar-person-10',
      'emotion_tracker-static-avatar-person-11',
      'emotion_tracker-static-avatar-person-12',
      'emotion_tracker-static-avatar-person-13',
      'emotion_tracker-static-avatar-person-14',
      'emotion_tracker-static-avatar-person-15',
      'emotion_tracker-static-avatar-person-16',
    ],
  ),
  const Bundle(
    id: 'emotion_tracker-themes-dark',
    name: 'Dark Theme Pack',
    description: 'A bundle featuring a collection of dark-themed UI elements.',
    price: 2500,
    includedItems: [
      'emotion_tracker-serenityGreenDark',
      'emotion_tracker-pacificBlueDark',
      'emotion_tracker-blushRoseDark',
      'emotion_tracker-cloudGrayDark',
      'emotion_tracker-sunsetPeachDark',
      'emotion_tracker-goldenYellowDark',
      'emotion_tracker-forestGreenDark',
      'emotion_tracker-midnightLavender',
      'emotion_tracker-crimsonRedDark',
      'emotion_tracker-deepPurpleDark',
      'emotion_tracker-royalOrangeDark',
    ],
  ),
  const Bundle(
    id: 'emotion_tracker-themes-light',
    name: 'Light Theme Pack',
    description: 'A bundle featuring a collection of light-themed UI elements.',
    price: 2500,
    includedItems: [
      'emotion_tracker-serenityGreen',
      'emotion_tracker-pacificBlue',
      'emotion_tracker-blushRose',
      'emotion_tracker-cloudGray',
      'emotion_tracker-sunsetPeach',
      'emotion_tracker-goldenYellow',
      'emotion_tracker-forestGreen',
      'emotion_tracker-midnightLavenderLight',
      'emotion_tracker-royalOrange',
      'emotion_tracker-crimsonRed',
      'emotion_tracker-deepPurple',
    ],
  ),
];

// --- UI Widgets ---
class BundleDisplay extends StatelessWidget {
  final Bundle bundle;
  final bool isSelected;

  const BundleDisplay({
    Key? key,
    required this.bundle,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? theme.primaryColor.withOpacity(0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? theme.primaryColor : Colors.grey.withOpacity(0.5),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bundle.name,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            bundle.description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Price: ${bundle.price} SBD',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.primaryColor),
          ),
        ],
      ),
    );
  }
}
