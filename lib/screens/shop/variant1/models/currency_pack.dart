/// Model class representing a currency pack available for purchase in the shop
class CurrencyPack {
  final String name;
  final String description;
  final int coins;
  final int price;
  final int bonus;
  final String tag;

  const CurrencyPack({
    required this.name,
    required this.description,
    required this.coins,
    required this.price,
    this.bonus = 0,
    this.tag = '',
  });

  /// Calculates the effective rate per coin including bonus
  String get effectiveRate {
    final totalCoins = coins + bonus;
    if (totalCoins == 0) return '0.000';
    return (price / totalCoins).toStringAsFixed(3);
  }

  /// Returns formatted bonus text for display
  String get bonusText {
    return bonus > 0 ? '+$bonus' : '—';
  }

  /// Returns total coins including bonus
  int get totalCoins => coins + bonus;

  /// Validates if the currency pack data is valid
  bool get isValid {
    return name.isNotEmpty &&
        description.isNotEmpty &&
        coins > 0 &&
        price > 0 &&
        bonus >= 0;
  }

  /// Creates a copy of this CurrencyPack with updated values
  CurrencyPack copyWith({
    String? name,
    String? description,
    int? coins,
    int? price,
    int? bonus,
    String? tag,
  }) {
    return CurrencyPack(
      name: name ?? this.name,
      description: description ?? this.description,
      coins: coins ?? this.coins,
      price: price ?? this.price,
      bonus: bonus ?? this.bonus,
      tag: tag ?? this.tag,
    );
  }

  @override
  String toString() {
    return 'CurrencyPack(name: $name, coins: $coins, price: $price, bonus: $bonus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurrencyPack &&
        other.name == name &&
        other.description == description &&
        other.coins == coins &&
        other.price == price &&
        other.bonus == bonus &&
        other.tag == tag;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        description.hashCode ^
        coins.hashCode ^
        price.hashCode ^
        bonus.hashCode ^
        tag.hashCode;
  }
}

/// Predefined currency packs available for purchase
final List<CurrencyPack> currencyPacks = [
  const CurrencyPack(
    name: 'Nano',
    description: 'A small token to support our ecosystem of apps.',
    coins: 200,
    price: 79,
  ),
  const CurrencyPack(
    name: 'Micro',
    description: 'Help us improve our apps and add new features.',
    coins: 500,
    price: 179,
    bonus: 50,
  ),
  const CurrencyPack(
    name: 'Standard',
    description:
        'A popular choice for enhancing your experience across our apps.',
    coins: 1200,
    price: 399,
    bonus: 200,
  ),
  const CurrencyPack(
    name: 'Mega',
    description: 'For those who love our ecosystem and want to see it thrive.',
    coins: 2500,
    price: 799,
    bonus: 500,
    tag: '🔥 Best Value',
  ),
  const CurrencyPack(
    name: 'Giga',
    description: 'The ultimate support for our ecosystem of apps.',
    coins: 6000,
    price: 1599,
    bonus: 1500,
    tag: '💎 Premium',
  ),
];
