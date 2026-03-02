import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/admin_sidebar.dart';
import '../providers/admin_providers.dart';
import 'admin_dashboard_screen.dart';
import 'admin_approve_users_screen.dart';
import 'admin_listings_screen.dart';
import 'admin_bids_screen.dart';
import 'admin_disputes_screen.dart';
import 'admin_flags_screen.dart';
import 'admin_ai_config_screen.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationProvider);

    final List<Widget> screens = [
      const AdminDashboardScreen(),      // Overview (0)
      const AdminApproveUsersScreen(),   // Users (1)
      const AdminListingsScreen(),       // Listings (2)
      const AdminBidsScreen(),           // Bids (3)
      const AdminDisputesScreen(),       // Disputes (4)
      const AdminFlagsScreen(),          // Flags (5)
      const AdminAiConfigScreen(),       // AI Config (6)
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart AgroTrade Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Navigation will be handled by AdminGate in main.dart
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          const AdminSidebar(),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: screens,
            ),
          ),
        ],
      ),
    );
  }
}
