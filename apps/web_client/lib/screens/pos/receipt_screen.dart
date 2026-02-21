import 'package:flutter/material.dart';
import '../../services/sale_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tenant_provider.dart';

// Import SaleService or similar to fetch sale details by ID if not passed entirely
final saleFutureProvider = FutureProvider.autoDispose
    .family<SaleWithItems?, String>((ref, saleId) async {
      return await SaleService().getSaleWithItems(saleId);
    });

class ReceiptScreen extends ConsumerWidget {
  final String saleId;

  const ReceiptScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleFutureProvider(saleId));

    return Scaffold(
      appBar: AppBar(title: const Text('Receipt Preview')),
      body: saleAsync.when(
        data: (saleData) {
          if (saleData == null)
            return const Center(child: Text('Sale not found'));
          return PdfPreview(
            build: (format) => _generateReceipt(format, saleData, ref),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<java> _generateReceipt(
    PdfPageFormat format,
    SaleWithItems saleData,
    WidgetRef ref,
  ) async {
    final pdf = pw.Document();

    // Fetch tenant details for header
    final tenantState = ref.read(tenantProvider).value;
    final tenantName = tenantState?.tenant?.name ?? 'Company Name';
    final tenantAddress = tenantState?.tenant?.address ?? 'Address';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                tenantName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(tenantAddress),
              pw.Divider(),
              pw.Text('Receipt: ${saleData.sale.saleNumber}'),
              pw.Text('Date: ${saleData.sale.createdAt ?? DateTime.now()}'),
              pw.Divider(),
              pw.ListView.builder(
                itemCount: saleData.items.length,
                itemBuilder: (context, index) {
                  final item = saleData.items[index];
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text(item.productName ?? 'Item')),
                      pw.Text(
                        '${item.quantity} x ${item.unitPrice.toStringAsFixed(2)}',
                      ),
                      pw.Text('${item.totalPrice.toStringAsFixed(2)}'),
                    ],
                  );
                },
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    '\$${saleData.sale.totalAmount.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Thank you for your business!'),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
