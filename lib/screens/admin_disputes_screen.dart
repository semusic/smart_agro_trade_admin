import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_providers.dart';
import '../models/models.dart';

class AdminDisputesScreen extends ConsumerWidget {
  const AdminDisputesScreen({super.key});

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
              'Dispute Resolution',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Dispute>>(
                stream: adminService.getDisputes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final disputes = snapshot.data ?? [];

                  return ListView.builder(
                    itemCount: disputes.length,
                    itemBuilder: (context, index) {
                      final dispute = disputes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ExpansionTile(
                          title: Text('Order: ${dispute.orderId}'),
                          subtitle: Text('Status: ${dispute.status.toUpperCase()} | Created: ${DateFormat('MMM dd, yyyy').format(dispute.createdAt)}'),
                          trailing: _buildStatusIcon(dispute.status),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Message: ${dispute.message}', style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Text('Listing ID: ${dispute.listingId}'),
                                  Text('Buyer: ${dispute.buyerId} | Farmer: ${dispute.farmerId}'),
                                  const Divider(height: 32),
                                  if (dispute.adminReply != null) ...[
                                    const Text('Admin Reply:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text(dispute.adminReply!),
                                    const SizedBox(height: 16),
                                  ],
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => _showReplyDialog(context, adminService, dispute.id),
                                        child: const Text('Add/Update Reply'),
                                      ),
                                      const SizedBox(width: 8),
                                      if (dispute.status == 'open')
                                        OutlinedButton(
                                          onPressed: () => adminService.updateDisputeStatus(dispute.id, 'closed'),
                                          child: const Text('Close Dispute'),
                                        )
                                      else
                                        OutlinedButton(
                                          onPressed: () => adminService.updateDisputeStatus(dispute.id, 'open'),
                                          child: const Text('Re-open Dispute'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  Widget _buildStatusIcon(String status) {
    return Icon(
      status == 'open' ? Icons.error_outline : Icons.check_circle_outline,
      color: status == 'open' ? Colors.red : Colors.green,
    );
  }

  void _showReplyDialog(BuildContext context, dynamic adminService, String id) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Reply'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Enter your response...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await adminService.addAdminReply(id, controller.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply added')));
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
