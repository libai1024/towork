import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Presentation-only subscription state. Never consumed by AI quotas or billing.
enum MembershipFamily {
  music('乐章'),
  alpine('山岳');

  const MembershipFamily(this.label);
  final String label;

  String englishName(int tier) => switch (this) {
    music => ['Note', 'Prelude', 'Sonata', 'Symphony'][tier],
    alpine => ['Vale', 'Ridge', 'Summit', 'Zenith'][tier],
  };
  String title(int tier) => switch (this) {
    music => ['音符', '序曲', '奏鸣曲', '交响曲'][tier],
    alpine => ['山谷', '山脊', '峰顶', '天顶'][tier],
  };
  String asset(int tier, String extension) =>
      'assets/membership/${englishName(tier).toLowerCase()}.$extension';
}

const membershipCredits = ['100', '500', '3,000', '10,000'];
const membershipLevels = ['Free', 'Beta', 'Pro', 'Max'];

int membershipTierForLabel(String label) {
  final value = label.toLowerCase();
  for (var i = 3; i > 0; i--) {
    if (value.contains(membershipLevels[i].toLowerCase()) ||
        MembershipFamily.values.any(
          (family) =>
              value.contains(family.title(i)) ||
              value.contains(family.englishName(i).toLowerCase()),
        )) {
      return i;
    }
  }
  return 0;
}

class MembershipPlan {
  const MembershipPlan({
    required this.family,
    required this.tier,
    this.annual = false,
  });
  final MembershipFamily family;
  final int tier;
  final bool annual;
  String get title => family.title(tier);
  String get name => family.englishName(tier);
  String get credits => membershipCredits[tier];
  int get price => switch (tier) {
    2 => annual ? 380 : 38,
    3 => annual ? 980 : 98,
    _ => 0,
  };
  String get period => annual ? '年' : '月';
}

// Deliberately scoped to the running app. No production identity is overwritten.
final membershipSelectionProvider = StateProvider<MembershipPlan?>(
  (ref) => null,
);
