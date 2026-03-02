import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminService = ref.watch(adminServiceProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Overview',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            FutureBuilder<Map<String, dynamic>>(
              future: adminService.getDashboardStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                final stats = snapshot.data!;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard('Total Users', stats['totalUsers'].toString(), Icons.people, Colors.blue),
                    _buildStatCard('Approved Users', stats['approvedUsers'].toString(), Icons.check_circle, Colors.green),
                    _buildStatCard('Pending Approvals', stats['pendingApprovals'].toString(), Icons.hourglass_empty, Colors.orange),
                    _buildStatCard('Active Listings', stats['activeListings'].toString(), Icons.list_alt, Colors.purple),
                    _buildStatCard('Sold Listings', stats['soldListings'].toString(), Icons.shopping_bag, Colors.indigo),
                    _buildStatCard('Open Disputes', stats['openDisputes'].toString(), Icons.gavel, Colors.red),
                    _buildStatCard('Total Bids', stats['totalBids'].toString(), Icons.monetization_on, Colors.amber),
                  ],
                );
              },
            ),
            const SizedBox(height: 48),
            Text(
              'Generate Reports',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildExportButton(context, ref, 'Users', 'users'),
                _buildExportButton(context, ref, 'Listings', 'listings'),
                _buildExportButton(context, ref, 'Bids', 'bids'),
                _buildExportButton(context, ref, 'Disputes', 'disputes'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(BuildContext context, WidgetRef ref, String label, String collection) {
    return ElevatedButton.icon(
      onPressed: () async {
        try {
          await ref.read(adminServiceProvider).exportToCsv(collection);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label report exported successfully.')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to export $label: $e')),
            );
          }
        }
      },
      icon: const Icon(Icons.download),
      label: Text('Export $label (CSV)'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }
}