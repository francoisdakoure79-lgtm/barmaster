import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class S1ProPrintService {
  static BluetoothDevice? _device;
  static BluetoothCharacteristic? _writeChar;
  static BluetoothCharacteristic? _notifyChar;
  static bool _connected = false;

  static final Guid SERVICE_UUID = Guid('0000ff00-0000-1000-8000-00805f9b34fb');
  static final Guid WRITE_CHAR_UUID = Guid('0000ff02-0000-1000-8000-00805f9b34fb');
  static final Guid NOTIFY_CHAR_UUID = Guid('0000ff01-0000-1000-8000-00805f9b34fb');

  static bool isConnected() => _connected;
  static BluetoothDevice? getDevice() => _device;

  static Future<bool> connect(String deviceId) async {
    try {
      _device = BluetoothDevice.fromId(deviceId);
      await _device!.connect(license: License.free, timeout: const Duration(seconds: 10));
      
      final services = await _device!.discoverServices();
      
      for (var service in services) {
        if (service.uuid == SERVICE_UUID) {
          for (var char in service.characteristics) {
            if (char.uuid == WRITE_CHAR_UUID) {
              _writeChar = char;
            }
            if (char.uuid == NOTIFY_CHAR_UUID) {
              _notifyChar = char;
              await char.setNotifyValue(true);
            }
          }
        }
      }
      
      _connected = _writeChar != null;
      print(_connected ? '✅ S1 PRO connectée' : '❌ Caractéristique write non trouvée');
      return _connected;
    } catch (e) {
      print('❌ Erreur connexion S1 PRO: $e');
      _connected = false;
      return false;
    }
  }

  static Future<void> disconnect() async {
    try {
      await _device?.disconnect();
    } catch (e) {}
    _connected = false;
    _writeChar = null;
    _notifyChar = null;
  }

  static Future<bool> printBytes(List<int> bytes) async {
    if (_writeChar == null || !_connected) return false;
    
    try {
      // Envoyer par chunks de 100 bytes
      const chunkSize = 100;
      for (var i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);
        await _writeChar!.write(chunk, withoutResponse: true);
        await Future.delayed(const Duration(milliseconds: 15));
      }
      print('✅ Données envoyées: ${bytes.length} bytes');
      return true;
    } catch (e) {
      print('❌ Erreur écriture BLE: $e');
      return false;
    }
  }

  static Future<List<ScanResult>> scanDevices() async {
    final results = <ScanResult>[];
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      
      FlutterBluePlus.scanResults.listen((scanResults) {
        for (var result in scanResults) {
          final name = result.device.platformName.toUpperCase();
          if (name.contains('PPS1') || name.contains('S1') || 
              name.contains('LUCK') || name.contains('PRINTER') ||
              name.contains('POS')) {
            if (!results.any((r) => r.device.remoteId == result.device.remoteId)) {
              results.add(result);
            }
          }
        }
      });
      
      await Future.delayed(const Duration(seconds: 15));
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print('❌ Erreur scan BLE: $e');
    }
    return results;
  }
}
