import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/local_database_service.dart';
import '../../services/sync_service.dart';
import '../../models/pending_sale.dart';
import 'package:intl/intl.dart';

/// Screen for viewing and managing pending offline sales
class PendingSalesScreen extends StatefulWidget {
  const PendingSalesScreen({super.key});

  @override
  State<PendingSalesScreen> createState() => _PendingSalesScreenState();
}

class _PendingSalesScreenState extends State<PendingSalesScreen> {
  bool _isLoading = false;
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final localDb = Provider.of<LocalDatabaseService>(context, listen: false);
    final syncService = Provider.of<SyncService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Sales (Offline Queue)'),
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => _manualSync(syncService),
              tooltip: 'Sync Now',
            ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: localDb.getPendingSales(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No pending sales',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All sales have been synced to Supabase',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final pendingSalesData = snapshot.data!;
          final pendingSales = pendingSalesData.map((data) => PendingSale.fromJson(data)).toList();

          // Group by status
          final pending = pendingSales.where((s) => s.syncStatus == 'pending').length;
          final syncing = pendingSales.where((s) => s.syncStatus == 'syncing').length;
          final failed = pendingSales.where((s) => s.syncStatus == 'failed').length;
          final synced = pendingSales.where((s) => s.syncStatus == 'synced').length;

          return Column(
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatusChip(label: 'Pending', count: pending, color: Colors.orange),
                    _StatusChip(label: 'Syncing', count: syncing, color: Colors.blue),
                    _StatusChip(label: 'Failed', count: failed, color: Colors.red),
                    _StatusChip(label: 'Synced', count: synced, color: Colors.green),
                  ],
                ),
              ),

              // List of pending sales
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: pendingSales.length,
                    itemBuilder: (context, index) {
                      final sale = pendingSales[index];
                      return _PendingSaleCard(
                        sale: sale,
                        onRetry: failed > 0 ? () => _retrySync(syncService, sale.id) : null,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _manualSync(SyncService syncService) async {
    final user = Supabase.instance.client.auth.currentUser;
    final branchId = user?.userMetadata?['branch_id'] as String?;

    if (branchId == null) {
      _showMessage('Branch not found');
      return;
    }

    setState(() => _isSyncing = true);

    try {
      await syncService.performFullSync(branchId);

      if (mounted) {
        _showMessage('Sync completed successfully', isError: false);
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Sync failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _retrySync(SyncService syncService, String saleId) async {
    setState(() => _isSyncing = true);

    try {
      await syncService.syncPendingSales();

      if (mounted) {
        _showMessage('Retry completed', isError: false);
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Retry failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _PendingSaleCard extends StatelessWidget {
  final PendingSale sale;
  final VoidCallback? onRetry;

  const _PendingSaleCard({
    required this.sale,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (sale.syncStatus) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'syncing':
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'synced':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(statusIcon, color: statusColor, size: 32),
        title: Text(
          sale.saleNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Total: NGN ${sale.totalAmount.toStringAsFixed(2)}'),
            Text('Created: ${dateFormat.format(sale.createdAt)}'),
            if (sale.syncStatus == 'failed' && sale.syncError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Error: ${sale.syncError}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              sale.syncStatus.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (sale.syncAttempts > 0)
              Text(
                'Attempts: ${sale.syncAttempts}',
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...sale.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('${item.quantity}x ${item.productName}'),
                          ),
                          Text(
                            'NGN ${item.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal:', style: TextStyle(color: Colors.grey[700])),
                    Text('NGN ${sale.subtotal.toStringAsFixed(2)}'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tax (7.5%):', style: TextStyle(color: Colors.grey[700])),
                    Text('NGN ${sale.taxAmount.toStringAsFixed(2)}'),
                  ],
                ),
                if (sale.discountAmount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Discount:', style: TextStyle(color: Colors.grey[700])),
                      Text('-NGN ${sale.discountAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      'NGN ${sale.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                if (sale.syncStatus == 'failed' && onRetry != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry Sync'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
