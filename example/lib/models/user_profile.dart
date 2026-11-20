/// Mock user profile for the ScenarioKit example app.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.memberSince,
    required this.tier,
    required this.orderCount,
    required this.wishlistCount,
    required this.loyaltyPoints,
    this.isEmailVerified = true,
    this.isGuest = false,
  });

  final String id;
  final String displayName;
  final String email;
  final String memberSince;
  final String tier;
  final int orderCount;
  final int wishlistCount;
  final int loyaltyPoints;
  final bool isEmailVerified;
  final bool isGuest;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class ProfileOrder {
  const ProfileOrder({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.total,
    required this.status,
  });

  final String id;
  final String title;
  final String dateLabel;
  final double total;
  final String status;
}

const mockProfileComplete = UserProfile(
  id: 'user_42',
  displayName: 'Jordan Lee',
  email: 'jordan.lee@gearstore.example',
  memberSince: 'March 2023',
  tier: 'Gold Member',
  orderCount: 24,
  wishlistCount: 8,
  loyaltyPoints: 1840,
  isEmailVerified: true,
);

const mockProfileUnverified = UserProfile(
  id: 'user_88',
  displayName: 'Jordan Lee',
  email: 'jordan.lee@gearstore.example',
  memberSince: 'March 2023',
  tier: 'Silver Member',
  orderCount: 12,
  wishlistCount: 3,
  loyaltyPoints: 420,
  isEmailVerified: false,
);

const mockProfileGuest = UserProfile(
  id: 'guest',
  displayName: 'Guest',
  email: '',
  memberSince: '',
  tier: 'Browse only',
  orderCount: 0,
  wishlistCount: 0,
  loyaltyPoints: 0,
  isGuest: true,
);

const mockProfileOrders = <ProfileOrder>[
  ProfileOrder(
    id: 'ord-1001',
    title: 'Wireless Noise-Canceling Headphones',
    dateLabel: 'Nov 12, 2025',
    total: 299.99,
    status: 'Delivered',
  ),
  ProfileOrder(
    id: 'ord-1002',
    title: 'Mechanical Gaming Keyboard',
    dateLabel: 'Oct 28, 2025',
    total: 149.50,
    status: 'Shipped',
  ),
  ProfileOrder(
    id: 'ord-1003',
    title: 'Ergonomic Vertical Mouse',
    dateLabel: 'Oct 03, 2025',
    total: 79.99,
    status: 'Delivered',
  ),
];