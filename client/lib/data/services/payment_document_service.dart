import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import '../repositories/payment_repository.dart';
import 'auth_service.dart';

class PaymentDocumentService {
  static Future<File> saveInvoicePdf(ApiPayment payment) async {
    final pdf = pw.Document();
    final user = AuthService.user ?? const <String, dynamic>{};
    final companyName = (user['companyName'] ?? 'KINETIC GYM').toString();
    final ownerName = (user['name'] ?? 'System Owner').toString();
    final companyAddress = (user['companyAddress'] ?? '').toString();
    final companyPhone = (user['phoneNumber'] ?? '').toString();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    companyName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (companyAddress.isNotEmpty) pw.SizedBox(height: 6),
                  if (companyAddress.isNotEmpty) pw.Text(companyAddress),
                  if (companyPhone.isNotEmpty) pw.Text('Phone: $companyPhone'),
                  pw.Text('Prepared by: $ownerName'),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Text(
                  payment.status.name.toUpperCase(),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 28),
          pw.Text(
            'PAYMENT INVOICE',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 18),
          _infoRow('Invoice', payment.invoiceNumber),
          _infoRow('Member', payment.memberName),
          _infoRow('Phone', payment.memberPhone ?? '-'),
          _infoRow('Email', payment.memberEmail ?? '-'),
          _infoRow('Package', payment.plan),
          _infoRow(
            'Billing Period',
            '${payment.billingPeriodStart ?? '-'} to ${payment.billingPeriodEnd ?? '-'}',
          ),
          _infoRow('Due Date', payment.dueDate),
          _infoRow('Payment Method', payment.paymentMethod.toUpperCase()),
          if (payment.receivedBy != null)
            _infoRow('Received By', payment.receivedBy!),
          pw.SizedBox(height: 24),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              border: pw.Border.all(color: PdfColors.grey500),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _moneyRow('Invoice Amount', payment.amount),
                _moneyRow('Paid Amount', payment.paidAmount),
                _moneyRow('Balance', payment.balanceAmount),
              ],
            ),
          ),
        ],
      ),
    );

    final baseDir =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final safeInvoice = payment.invoiceNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File('${baseDir.path}\\$safeInvoice.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> openWhatsAppForPayment(
    ApiPayment payment, {
    String? attachmentPath,
  }) async {
    final phone = _normalizePhone(payment.memberPhone);
    final message = StringBuffer()
      ..writeln('Hello ${payment.memberName},')
      ..writeln('Your invoice ${payment.invoiceNumber} is ready.')
      ..writeln('Package: ${payment.plan}')
      ..writeln('Amount: Rs.${payment.amount.toStringAsFixed(2)}')
      ..writeln('Due Date: ${payment.dueDate}');

    if (attachmentPath != null && attachmentPath.isNotEmpty) {
      message
        ..writeln()
        ..writeln('PDF saved locally:')
        ..writeln(attachmentPath);
    }

    final encoded = Uri.encodeComponent(message.toString());
    final url = phone != null && phone.isNotEmpty
        ? Uri.parse('https://wa.me/$phone?text=$encoded')
        : Uri.parse('https://web.whatsapp.com/send?text=$encoded');

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label.toUpperCase(),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static pw.Widget _moneyRow(String label, double value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(
            'Rs.${value.toStringAsFixed(2)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static String? _normalizePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null;
    final trimmed = phone.trim();
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    // Already has full international format: +94XXXXXXXXX → 94XXXXXXXXX
    if (hasPlus) return digits;
    // Sri Lanka local: 07XXXXXXXX (10 digits starting with 0) → 947XXXXXXXX
    if (digits.startsWith('0') && digits.length == 10) {
      return '94${digits.substring(1)}';
    }
    // Already has 94 prefix
    if (digits.startsWith('94') && digits.length == 11) return digits;
    // 9-digit without leading 0: 7XXXXXXXX → 947XXXXXXXX
    if (digits.length == 9) return '94$digits';
    return digits;
  }
}
