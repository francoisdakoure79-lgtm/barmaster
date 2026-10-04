import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

class PdfTicketService {
  static Future<File> generateTicketPdf({
    required String ticketNumber,
    required String date,
    required String paymentMethod,
    required double total,
    required List<Map<String, dynamic>> items,
    required String shopName,
    required String shopPhone,
    required String shopAddress,
    required String shopSlogan,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(children: [
                  pw.Text(shopName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  if (shopSlogan.isNotEmpty) pw.Text(shopSlogan, style: const pw.TextStyle(fontSize: 10)),
                  if (shopAddress.isNotEmpty) pw.Text(shopAddress, style: const pw.TextStyle(fontSize: 10)),
                  if (shopPhone.isNotEmpty) pw.Text(shopPhone, style: const pw.TextStyle(fontSize: 10)),
                ]),
              ),
              pw.Divider(),
              pw.Text('Ticket: $ticketNumber', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Date: $date', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Paiement: $paymentMethod', style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(),
              ...items.map((item) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${item['name']} x${item['quantity']}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('${item['total']} F', style: const pw.TextStyle(fontSize: 10)),
                ],
              )),
              pw.Divider(thickness: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text('${total.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Merci de votre visite !', style: const pw.TextStyle(fontSize: 10))),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/ticket_$ticketNumber.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> shareTicketPdf({
    required String ticketNumber,
    required String date,
    required String paymentMethod,
    required double total,
    required List<Map<String, dynamic>> items,
    required String shopName,
    required String shopPhone,
    required String shopAddress,
    required String shopSlogan,
  }) async {
    final pdfBytes = await generateTicketPdfBytes(
      ticketNumber: ticketNumber, date: date, paymentMethod: paymentMethod,
      total: total, items: items, shopName: shopName, shopPhone: shopPhone,
      shopAddress: shopAddress, shopSlogan: shopSlogan,
    );

    if (kIsWeb) {
      // Web : télécharger automatiquement le PDF
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'ticket_$ticketNumber.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
      return;
    }

    // Mobile : partager via Android
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/ticket_$ticketNumber.pdf');
    await file.writeAsBytes(pdfBytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Ticket $ticketNumber');
  }

  // Générer les bytes du PDF (pour Web et Mobile)
  static Future<Uint8List> generateTicketPdfBytes({
    required String ticketNumber,
    required String date,
    required String paymentMethod,
    required double total,
    required List<Map<String, dynamic>> items,
    required String shopName,
    required String shopPhone,
    required String shopAddress,
    required String shopSlogan,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(children: [
                  pw.Text(shopName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  if (shopSlogan.isNotEmpty) pw.Text(shopSlogan, style: const pw.TextStyle(fontSize: 10)),
                  if (shopAddress.isNotEmpty) pw.Text(shopAddress, style: const pw.TextStyle(fontSize: 10)),
                  if (shopPhone.isNotEmpty) pw.Text(shopPhone, style: const pw.TextStyle(fontSize: 10)),
                ]),
              ),
              pw.Divider(),
              pw.Text('Ticket: $ticketNumber', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Date: $date', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Paiement: $paymentMethod', style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(),
              ...items.map((item) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${item['name']} x${item['quantity']}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('${item['total']} F', style: const pw.TextStyle(fontSize: 10)),
                ],
              )),
              pw.Divider(thickness: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text('${total.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Merci de votre visite !', style: const pw.TextStyle(fontSize: 10))),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }
}
