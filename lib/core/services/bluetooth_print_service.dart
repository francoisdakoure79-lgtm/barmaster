import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

class BluetoothPrintService {
  static BluetoothConnection? _connection;
  static bool _isConnected = false;

  // ============================================================
  // CONNEXION BLUETOOTH
  // ============================================================

  static Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      return devices.where((d) => d.name?.isNotEmpty ?? false).toList();
    } catch (e) {
      print('❌ Erreur récupération périphériques: $e');
      return [];
    }
  }

  static Future<bool> connect(String address) async {
    try {
      _connection = await BluetoothConnection.toAddress(address);
      _isConnected = true;
      print('✅ Connecté à l\'imprimante Bluetooth');
      return true;
    } catch (e) {
      print('❌ Erreur connexion: $e');
      _isConnected = false;
      return false;
    }
  }

  static void disconnect() {
    if (_connection != null) {
      _connection!.close();
      _connection = null;
      _isConnected = false;
      print('🔌 Déconnecté de l\'imprimante');
    }
  }

  static bool isConnected() {
    return _isConnected && _connection != null;
  }

  // ============================================================
  // IMPRESSION DU TICKET
  // ============================================================

  static Future<bool> printTicket({
    required String ticketNumber,
    required String date,
    required String paymentMethod,
    required double total,
    required List<Map<String, dynamic>> items,
    required String shopName,
    required String shopPhone,
    required String shopAddress,
  }) async {
    if (!isConnected()) {
      print('❌ Imprimante non connectée');
      return false;
    }

    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);

      final bytes = await _generateTicketBytes(
        ticketNumber: ticketNumber,
        date: date,
        paymentMethod: paymentMethod,
        total: total,
        items: items,
        shopName: shopName,
        shopPhone: shopPhone,
        shopAddress: shopAddress,
      );

      if (_connection != null && _connection!.isConnected) {
        _connection!.output.add(bytes);
        await _connection!.output.allSent;
        print('✅ Ticket imprimé avec succès');
        return true;
      } else {
        print('❌ Connexion perdue');
        return false;
      }
    } catch (e) {
      print('❌ Erreur impression: $e');
      return false;
    }
  }

  static Future<Uint8List> _generateTicketBytes({
    required String ticketNumber,
    required String date,
    required String paymentMethod,
    required double total,
    required List<Map<String, dynamic>> items,
    required String shopName,
    required String shopPhone,
    required String shopAddress,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    List<int> bytes = [];

    // Initialiser l'imprimante
    bytes.addAll(generator.reset());

    // En-tête
    bytes.addAll(generator.text(shopName, styles: const PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2)));
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text(shopAddress, styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.text(shopPhone, styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text('=' * 32, styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.feed(1));

    // Infos ticket
    bytes.addAll(generator.text('Ticket: $ticketNumber', styles: const PosStyles(align: PosAlign.left)));
    bytes.addAll(generator.text('Date: $date', styles: const PosStyles(align: PosAlign.left)));
    bytes.addAll(generator.text('Paiement: $paymentMethod', styles: const PosStyles(align: PosAlign.left)));
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text('-' * 32, styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.feed(1));

    // Articles
    for (var item in items) {
      final line = '${item['name']} x${item['quantity']} = ${(item['total'] as double).toStringAsFixed(0)} FCFA';
      bytes.addAll(generator.text(line, styles: const PosStyles(align: PosAlign.left)));
    }

    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text('-' * 32, styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.feed(1));

    // Total
    bytes.addAll(generator.text('TOTAL: ${total.toStringAsFixed(0)} FCFA', styles: const PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2)));
    bytes.addAll(generator.feed(1));

    // Pied de page
    bytes.addAll(generator.text('=' * 32, styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text('Merci de votre visite !', styles: const PosStyles(bold: true, align: PosAlign.center)));
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text(DateTime.now().toString().substring(0, 16), styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.feed(2));

    // Couper le papier
    bytes.addAll(generator.cut());

    return Uint8List.fromList(bytes);
  }

  // ============================================================
  // TEST DE CONNEXION
  // ============================================================

  static Future<bool> testPrint() async {
    if (!isConnected()) {
      print('❌ Imprimante non connectée');
      return false;
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);

      List<int> bytes = [];
      bytes.addAll(generator.reset());
      bytes.addAll(generator.text('TEST IMPRESSION', styles: const PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2)));
      bytes.addAll(generator.feed(1));
      bytes.addAll(generator.text('Connexion Bluetooth OK !', styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(generator.feed(2));
      bytes.addAll(generator.cut());

      if (_connection != null && _connection!.isConnected) {
        _connection!.output.add(Uint8List.fromList(bytes));
        await _connection!.output.allSent;
        print('✅ Test d\'impression réussi');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur test: $e');
      return false;
    }
  }
}
