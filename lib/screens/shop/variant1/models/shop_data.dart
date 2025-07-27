import 'currency_pack.dart';

/// Predefined currency packs available in the shop
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
