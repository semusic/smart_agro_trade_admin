import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_providers.dart';
import '../models/models.dart';

class AdminListingsScreen extends ConsumerWidget {
  const AdminListingsScreen({super.key});

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
              'Produce Listings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Listing>>(
                stream: adminService.getListings(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final listings = snapshot.data ?? [];

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Crop Name')),
                          DataColumn(label: Text('Farmer')),
                          DataColumn(label: Text('Location')),
                          DataColumn(label: Text('Price')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Created At')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: listings.map((listing) => DataRow(cells: [
                          DataCell(Text(listing.cropName)),
                          DataCell(Text(listing.farmerName)),
                          DataCell(Text(listing.location)),
                          DataCell(Text('\$${listing.price.toStringAsFixed(2)}')),
                          DataCell(_buildStatusChip(listing.status, listing.isFlagged)),
                          DataCell(Text(DateFormat('MMM dd, yyyy').format(listing.createdAt))),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.flag, color: Colors.orange),
                                tooltip: 'Flag Listing',
                                onPressed: () => _showFlagDialog(context, adminService, listing.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.disabled_by_default, color: Colors.red),
                                tooltip: 'Disable Listing',
                                onPressed: () => _confirmAction(context, 'Disable ${listing.cropName}?', 
                                  () => adminService.disableListing(listing.id)),
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
      return const Chip(label: Text('Flagged'), backgroundColor: Colors.orangeAccent);
    }
    switch (status) {
      case 'active':
        return const Chip(label: Text('Active'), backgroundColor: Colors.greenAccent);
      case 'sold':
        return const Chip(label: Text('Sold'), backgroundColor: Colors.blueAccent);
      case 'disabled':
        return const Chip(label: Text('Disabled'), backgroundColor: Colors.redAccent);
      default:
        return Chip(label: Text(status));
    }
  }

  void _showFlagDialog(BuildContext context, dynamic adminService, String id) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag Listing'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason for flagging'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await adminService.flagListing(id, controller.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing flagged')));
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
