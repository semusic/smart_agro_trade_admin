import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_service.dart';

// Modern Riverpod Notifier for navigation
class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final navigationProvider = NotifierProvider<NavigationNotifier, int>(() {
  return NavigationNotifier();
});

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});
