import 'dart:typed_data';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

class PrintService {
  static BluetoothConnection? _connection;
  static bool _bluetoothConnected = false;

  static Future<bool> connectBluetooth(String address) async {
    try {
      _connection = await BluetoothConnection.toAddress(address);
      _bluetoothConnected = true;
      print('✅ Connecté à l\'imprimante Bluetooth');
      return true;
    } catch (e) {
      print('❌ Erreur connexion: $e');
      _bluetoothConnected = false;
      return false;
    }
  }

  static void disconnectBluetooth() {
    if (_connection != null) {
      _connection!.close();
      _connection = null;
      _bluetoothConnected = false;
      print('🔌 Déconnecté');
    }
  }

  static bool isBluetoothConnected() {
    return _bluetoothConnected && _connection != null;
  }

  static Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      return devices.where((d) => d.name?.isNotEmpty ?? false).toList();
    } catch (e) {
      print('❌ Erreur: $e');
      return [];
    }
  }

  static Future<bool> printBluetooth({
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
    if (!isBluetoothConnected()) {
      print('❌ Imprimante non connectée');
      return false;
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);

      List<int> bytes = [];
      bytes.addAll(generator.reset());
      bytes.addAll(generator.text(shopName, styles: const PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2)));
      bytes.addAll(generator.text(shopSlogan, styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(generator.text(shopAddress, styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(generator.text(shopPhone, styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(generator.feed(1));
      bytes.addAll(generator.text('=' * 32, styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(generator.feed(1));
      bytes.addAll(generator.text('Ticket: $ticketNumber', styles: const PosStyles(align: PosAlign.left)));
      bytes.addAll(generator.text('Date: $date', styles: const PosStyles(align: PosAlign.left)));
      bytes.addAll(generator.text('Paiement: $paymentMethod', styles: const PosStyles(align: PosAlign.left)));
      bytes.addAll(generator.feed(1));
      bytes.addAll(generator.text('-' * 32, styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(generator.feed(1));

      for (var item in items) {
        final line = '${item['name']} x${item['quantity']} = ${(item['total'] as double).toStringAsFixed(0)} FCFA';
        bytes.addAll(generator.text(line, styles: const PosStyles(align: PosAlign.left)));
      }

      bytes.addAll(generator.feed(1));
      bytes.addAll(generator.text('-' * 32, styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(generator.feed(1));
      bytes.addAll(generator.text('TOTAL: ${total.toStringAsFixed(0)} FCFA', styles: const PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2)));
      bytes.addAll(generator.feed(1));
      bytes.addAll(generator.text('=' * 32, styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(generator.feed(1));
      bytes.addAll(generator.text('Merci de votre visite !', styles: const PosStyles(bold: true, align: PosAlign.center)));
      bytes.addAll(generator.feed(1));
      bytes.addAll(generator.text(shopName, styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(generator.text(DateTime.now().toString().substring(0, 16), styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(generator.feed(2));
      bytes.addAll(generator.cut());

      if (_connection != null && _connection!.isConnected) {
        _connection!.output.add(Uint8List.fromList(bytes));
        await _connection!.output.allSent;
        print('✅ Ticket imprimé via Bluetooth');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur impression Bluetooth: $e');
      return false;
    }
  }

  static Future<bool> printSimulation({
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
    print('');
    print('🖨️ ========== SIMULATION ==========');
    print('🖨️ $shopName');
    print('🖨️ $shopSlogan');
    print('🖨️ $shopAddress');
    print('🖨️ $shopPhone');
    print('🖨️ --------------------------------');
    print('🖨️ Ticket: $ticketNumber');
    print('🖨️ Date: $date');
    print('🖨️ Paiement: $paymentMethod');
    print('🖨️ --------------------------------');
    print('🖨️ Articles:');
    for (var item in items) {
      print('🖨️   ${item['name']} x${item['quantity']} = ${(item['total'] as double).toStringAsFixed(0)} FCFA');
    }
    print('🖨️ --------------------------------');
    print('🖨️ TOTAL: ${total.toStringAsFixed(0)} FCFA');
    print('🖨️ ================================');
    print('🖨️ Merci de votre visite !');
    print('🖨️ $shopName');
    print('');
    return true;
  }

  static Future<bool> printTicket({
    required String ticketNumber,
    required String date,
    required String paymentMethod,
    required double total,
    required List<Map<String, dynamic>> items,
    required String shopName,
    required String shopPhone,
    required String shopAddress,
    required String shopSlogan,
    required String printMode,
  }) async {
    if (printMode == 'bluetooth') {
      return await printBluetooth(
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
    } else {
      return await printSimulation(
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
    }
  }
}
