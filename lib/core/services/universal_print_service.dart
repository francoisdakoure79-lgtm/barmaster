import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 's1pro_print_service.dart';

enum PrinterProtocol { escPosClassic, escPosBle, s1proLuck, pdf }

class UniversalPrintService {
  // Générer les bytes ESC/POS pour un ticket
  static Future<List<int>> generateEscPosBytes({
    required String ticketNumber,
    required String date,
    required String paymentMethod,
    required double total,
    required List<Map<String, dynamic>> items,
    required String shopName,
    required String shopPhone,
    required String shopAddress,
    required String shopSlogan,
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);

    List<int> bytes = [];
    bytes += generator.reset();
    bytes += generator.text(shopName, styles: const PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text(shopSlogan, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(shopAddress, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(shopPhone, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(1);
    bytes += generator.text('=' * 32);
    bytes += generator.text('Ticket: $ticketNumber');
    bytes += generator.text('Date: $date');
    bytes += generator.text('Paiement: $paymentMethod');
    bytes += generator.text('-' * 32);

    for (var item in items) {
      final line = '${item['name']} x${item['quantity']} = ${(item['total'] as double).toStringAsFixed(0)} FCFA';
      bytes += generator.text(line);
    }

    bytes += generator.text('-' * 32);
    bytes += generator.text('TOTAL: ${total.toStringAsFixed(0)} FCFA',
        styles: const PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.feed(2);
    bytes += generator.cut();
    
    return bytes;
  }

  // Convertir du texte en image (pour S1 PRO qui nécessite une image)
  static Future<List<int>> generateS1ProBytes({
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
    // Pour S1 PRO, on envoie un flux ESC/POS standard
    // L'imprimante accepte les commandes texte
    return generateEscPosBytes(
      ticketNumber: ticketNumber,
      date: date,
      paymentMethod: paymentMethod,
      total: total,
      items: items,
      shopName: shopName,
      shopPhone: shopPhone,
      shopAddress: shopAddress,
      shopSlogan: shopSlogan,
      paperSize: PaperSize.mm58,
    );
  }

  // Impression universelle
  static Future<bool> print({
    required PrinterProtocol protocol,
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
    switch (protocol) {
      case PrinterProtocol.s1proLuck:
      case PrinterProtocol.escPosBle:
        final bytes = await generateS1ProBytes(
          ticketNumber: ticketNumber,
          date: date,
          paymentMethod: paymentMethod,
          total: total,
          items: items,
          shopName: shopName,
          shopPhone: shopPhone,
          shopAddress: shopAddress,
          shopSlogan: shopSlogan,
        );
        return await S1ProPrintService.printBytes(bytes);
      default:
        return false;
    }
  }
}
