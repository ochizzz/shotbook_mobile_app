import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Consecutive days with a shot or a recipe opened. 0 = no streak yet.
/// (Placeholder until the streak tracker lands.)
final streakDaysProvider = Provider<int>((ref) => 0);
