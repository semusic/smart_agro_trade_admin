import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_providers.dart';
import '../models/models.dart';

class AdminFlagsScreen extends ConsumerWidget {
  const AdminFlagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminService = ref.watch(adminServiceProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Flags',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<SystemFlag>>(
                stream: adminService.getFlags(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final flags = snapshot.data ?? [];

                  if (flags.isEmpty) {
                    return const Center(child: Text('No flagged items found.'));
                  }

                  return ListView.builder(
                    itemCount: flags.length,
                    itemBuilder: (context, index) {
                      final flag = flags[index];
                      return ListTile(
                        leading: _buildTypeIcon(flag.type),
                        title: Text('Target: ${flag.targetId}'),
                        subtitle: Text('Reason: ${flag.reason}\nAdmin: ${flag.adminId} | ${DateFormat('MMM dd, HH:mm').format(flag.createdAt)}'),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () {
                            int navIndex = 0;
                            if (flag.type == 'listing') navIndex = 2;
                            if (flag.type == 'bid') navIndex = 3;
                            if (flag.type == 'user') navIndex = 1;
                            ref.read(navigationProvider.notifier).setIndex(navIndex);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    switch (type) {
      case 'user': return const Icon(Icons.person, color: Colors.blue);
      case 'listing': return const Icon(Icons.shopping_basket, color: Colors.green);
      case 'bid': return const Icon(Icons.gavel, color: Colors.orange);
      default: return const Icon(Icons.flag);
    }
  }
}
