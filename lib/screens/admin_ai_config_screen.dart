import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_providers.dart';
import '../models/models.dart';

class AdminAiConfigScreen extends ConsumerStatefulWidget {
  const AdminAiConfigScreen({super.key});

  @override
  ConsumerState<AdminAiConfigScreen> createState() => _AdminAiConfigScreenState();
}

class _AdminAiConfigScreenState extends ConsumerState<AdminAiConfigScreen> {
  final _versionController = TextEditingController();
  final _urlController = TextEditingController();
  double _threshold = 0.75;
  bool _isInit = false;

  @override
  void dispose() {
    _versionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminService = ref.watch(adminServiceProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: StreamBuilder<AiConfig>(
          stream: adminService.getAiConfig(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final config = snapshot.data!;
            
            if (!_isInit) {
              _versionController.text = config.modelVersion;
              _urlController.text = config.apiBaseUrl;
              _threshold = config.confidenceThreshold;
              _isInit = true;
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Model Configuration',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Last Updated: ${DateFormat('MMM dd, yyyy HH:mm').format(config.updatedAt)}', 
                       style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _versionController,
                            decoration: const InputDecoration(
                              labelText: 'Model Version',
                              border: OutlineInputBorder(),
                              helperText: 'e.g., tomato_v2.1',
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _urlController,
                            decoration: const InputDecoration(
                              labelText: 'API Base URL',
                              border: OutlineInputBorder(),
                              helperText: 'Endpoint for AI analysis requests',
                            ),
                          ),
                          const SizedBox(height: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Confidence Threshold: ${(_threshold * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Slider(
                                value: _threshold,
                                min: 0.5,
                                max: 0.95,
                                divisions: 9,
                                label: _threshold.toStringAsFixed(2),
                                onChanged: (val) => setState(() => _threshold = val),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () async {
                                await adminService.updateAiConfig(
                                  _versionController.text,
                                  _urlController.text,
                                  _threshold,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('AI Configuration updated successfully')),
                                  );
                                }
                              },
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const AlertBox(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class AlertBox extends StatelessWidget {
  const AlertBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Changes to AI configuration are applied in real-time. Ensure the API Base URL is correct to avoid system-wide analysis failures.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
