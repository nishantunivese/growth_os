import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/finance/domain/finance_models.dart';

class ReportExportService {
  /// Generates a CSV string representation of all financial activity
  static String generateCsvReport({
    required List<IncomeEntry> incomes,
    required List<ExpenseEntry> expenses,
    required FinancialSummary summary,
    required String userName,
  }) {
    final StringBuffer csv = StringBuffer();
    csv.writeln('GROWTH OS - EXECUTIVE FINANCIAL REPORT');
    csv.writeln('Generated For:,$userName');
    csv.writeln('Date:,"${DateTime.now().toIso8601String()}"');
    csv.writeln('');
    csv.writeln('EXECUTIVE SUMMARY');
    csv.writeln('Gross Revenue,₹${summary.grossRevenue.toStringAsFixed(2)}');
    csv.writeln('Total Operating Expenses,₹${summary.totalExpenses.toStringAsFixed(2)}');
    csv.writeln('Total Refunds,₹${summary.totalRefunds.toStringAsFixed(2)}');
    csv.writeln('Net Realized Profit,₹${summary.netProfit.toStringAsFixed(2)}');
    csv.writeln('Best Performing Channel,${summary.bestEarningSource}');
    csv.writeln('');
    csv.writeln('DETAILED LEDGER ENTRIES');
    csv.writeln('Date,Type,Channel / Category,Description,Status,Amount (INR)');

    // Combine transactions sorted by date descending
    final List<Map<String, dynamic>> ledger = [];
    for (var inc in incomes) {
      ledger.add({
        'date': inc.date,
        'type': 'INCOME',
        'category': inc.platformSource,
        'desc': inc.description,
        'status': inc.paymentStatus,
        'amount': inc.amount,
      });
    }
    for (var exp in expenses) {
      ledger.add({
        'date': exp.date,
        'type': exp.isRefund ? 'REFUND' : 'EXPENSE',
        'category': exp.category,
        'desc': exp.description,
        'status': 'Paid',
        'amount': -exp.amount,
      });
    }

    ledger.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    for (var row in ledger) {
      final dateStr = (row['date'] as DateTime).toIso8601String().split('T').first;
      final desc = row['desc'].toString().replaceAll('"', '""');
      csv.writeln('"$dateStr","${row['type']}","${row['category']}","$desc","${row['status']}",${row['amount']}');
    }

    return csv.toString();
  }

  /// Generates a downloadable PDF report and triggers system print/share sheet
  static Future<void> exportPdfReport({
    required BuildContext context,
    required List<IncomeEntry> incomes,
    required List<ExpenseEntry> expenses,
    required FinancialSummary summary,
    required String businessName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GROWTH OS',
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                      ),
                      pw.Text(
                        'Business & Financial Performance Statement',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text(
                    '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              // Executive Summary Grid
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildPdfMetric('Gross Revenue', '₹${summary.grossRevenue.toStringAsFixed(0)}', PdfColors.indigo800),
                    _buildPdfMetric('Expenses & Costs', '₹${summary.totalExpenses.toStringAsFixed(0)}', PdfColors.red800),
                    _buildPdfMetric('Refunds', '₹${summary.totalRefunds.toStringAsFixed(0)}', PdfColors.orange800),
                    _buildPdfMetric('Net Profit', '₹${summary.netProfit.toStringAsFixed(0)}', PdfColors.green800),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Platform Channel Breakdown
              pw.Text(
                'Platform & Channel Distribution',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Source / Channel', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Contribution (₹)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('% of Revenue', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...summary.platformBreakdown.entries.map((entry) {
                    final pct = summary.grossRevenue > 0 ? (entry.value / summary.grossRevenue) * 100 : 0.0;
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(entry.key, style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('₹${entry.value.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${pct.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 9))),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 24),

              // Footer Note
              pw.Text(
                'Confidential Document • Generated automatically by GROWTH OS mobile platform.',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Growth_OS_Financial_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildPdfMetric(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }
}

