import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_providers.dart';
import '../models/models.dart';

class AdminApproveUsersScreen extends ConsumerStatefulWidget {
  const AdminApproveUsersScreen({super.key});

  @override
  ConsumerState<AdminApproveUsersScreen> createState() => _AdminApproveUsersScreenState();
}

class _AdminApproveUsersScreenState extends ConsumerState<AdminApproveUsersScreen> {
  bool _pendingOnly = false;

  @override
  Widget build(BuildContext context) {
    final adminService = ref.watch(adminServiceProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'User Management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Text('Pending Only'),
                    Switch(
                      value: _pendingOnly,
                      onChanged: (val) => setState(() => _pendingOnly = val),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<AppUser>>(
                stream: adminService.getUsers(pendingOnly: _pendingOnly),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final users = snapshot.data ?? [];

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Role')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Created At')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: users.map((user) => DataRow(cells: [
                          DataCell(Text(user.name)),
                          DataCell(Text(user.email)),
                          DataCell(Text(user.role.toUpperCase())),
                          DataCell(_buildStatusChip(user)),
                          DataCell(Text(DateFormat('MMM dd, yyyy').format(user.createdAt))),
                          DataCell(Row(
                            children: [
                              if (!user.isApproved && !user.isRejected)
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  tooltip: 'Approve',
                                  onPressed: () => _confirmAction(context, 'Approve ${user.name}?', 
                                    () => adminService.approveUser(user.uid)),
                                ),
                              if (!user.isApproved && !user.isRejected)
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  tooltip: 'Reject',
                                  onPressed: () => _confirmAction(context, 'Reject ${user.name}?', 
                                    () => adminService.rejectUser(user.uid)),
                                ),
                              IconButton(
                                icon: Icon(
                                  user.isBlocked ? Icons.lock_open : Icons.block,
                                  color: user.isBlocked ? Colors.blue : Colors.orange,
                                ),
                                tooltip: user.isBlocked ? 'Unblock' : 'Block',
                                onPressed: () => _confirmAction(
                                  context, 
                                  '${user.isBlocked ? 'Unblock' : 'Block'} ${user.name}?', 
                                  () => adminService.toggleUserBlock(user.uid, !user.isBlocked)
                                ),
                              ),
                            ],
                          )),
                        ])).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(AppUser user) {
    if (user.isBlocked) return const Chip(label: Text('Blocked'), backgroundColor: Colors.redAccent);
    if (user.isRejected) return const Chip(label: Text('Rejected'), backgroundColor: Colors.grey);
    if (user.isApproved) return const Chip(label: Text('Approved'), backgroundColor: Colors.greenAccent);
    return const Chip(label: Text('Pending'), backgroundColor: Colors.orangeAccent);
  }

  Future<void> _confirmAction(BuildContext context, String title, Future<void> Function() action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await action();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action completed successfully')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}