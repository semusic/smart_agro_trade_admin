import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_providers.dart';
import '../models/models.dart';

class AdminBidsScreen extends ConsumerWidget {
  const AdminBidsScreen({super.key});

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
              'Bidding Activity',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Bid>>(
                stream: adminService.getBids(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final bids = snapshot.data ?? [];

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Listing ID')),
                          DataColumn(label: Text('Buyer Name')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Time')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: bids.map((bid) => DataRow(cells: [
                          DataCell(Text(bid.listingId)),
                          DataCell(Text(bid.buyerName)),
                          DataCell(Text('\$${bid.amount.toStringAsFixed(2)}')),
                          DataCell(_buildStatusChip(bid.status, bid.isFlagged)),
                          DataCell(Text(DateFormat('MMM dd, HH:mm').format(bid.createdAt))),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.flag, color: Colors.orange),
                                tooltip: 'Flag Bid',
                                onPressed: () => _showFlagDialog(context, adminService, bid.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.block, color: Colors.red),
                                tooltip: 'Ban Bidder',
                                onPressed: () => _confirmAction(context, 'Block bidder ${bid.buyerName}?', 
                                  () => adminService.toggleUserBlock(bid.buyerId, true)),
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

  Widget _buildStatusChip(String status, bool isFlagged) {
    if (isFlagged) {
      return const Chip(label: Text('Suspicious'), backgroundColor: Colors.orangeAccent);
    }
    return Chip(label: Text(status.toUpperCase()));
  }

  void _showFlagDialog(BuildContext context, dynamic adminService, String id) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag Bid'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason for flagging'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await adminService.flagBid(id, controller.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid flagged')));
                }
              }
            },
            child: const Text('Flag'),
          ),
        ],
      ),
    );
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
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action successful')));
      }
    }
  }
}
