import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The community feed (posting, joining challenges) is built but not yet
/// open: until there are people to fill it, the Feed tab shows a
/// "coming soon" page. Flip to true to open it.
final communityEnabledProvider = Provider<bool>((ref) => false);

/// The "N days in a row" badge (Discover, Profile) is hidden for now.
final streakBadgeEnabledProvider = Provider<bool>((ref) => false);
