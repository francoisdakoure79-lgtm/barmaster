import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import '../../../core/services/print_service.dart';
import '../../../core/services/s1pro_print_service.dart';
import '../../../shared/theme/app_theme.dart';

class PrintSettingsScreen extends StatefulWidget {
  const PrintSettingsScreen({super.key});

  @override
  State<PrintSettingsScreen> createState() => _PrintSettingsScreenState();
}

class _PrintSettingsScreenState extends State<PrintSettingsScreen> {
  String _selectedMode = 'pdf';
  List<BluetoothDevice> _devices = [];
  String? _selectedDevice;
  bool _isScanning = false;
  bool _isConnected = false;

  final List<String> _printModes = [
    'pdf',
    'bluetooth_classic',
    'bluetooth_ble_s1pro',
    'bluetooth_ble_espos',
  ];

  final Map<String, String> _modeLabels = {
    'pdf': '📄 PDF',
    'bluetooth_classic': '🖨️ Bluetooth Classique (SPP)',
    'bluetooth_ble_s1pro': '🖨️ Bluetooth BLE - S1 PRO / LuckPrinter',
    'bluetooth_ble_espos': '🖨️ Bluetooth BLE - ESC/POS',
  };

  final Map<String, String> _modeDescriptions = {
    'pdf': 'Génère un ticket en PDF (téléchargement ou impression)',
    'bluetooth_classic': 'Imprimante ESC/POS standard (Xprinter, Goojprt...)',
    'bluetooth_ble_s1pro': 'Imprimante S1 PRO / PPS1 (protocole LuckPrinter)',
    'bluetooth_ble_espos': 'Imprimante BLE compatible ESC/POS',
  };

  @override
  void initState() {
    super.initState();
    _loadSavedMode();
  }

  Future<void> _loadSavedMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('print_mode') ?? 'pdf';
    setState(() {
      _selectedMode = savedMode;
    });
    if (_selectedMode.startsWith('bluetooth')) {
      _loadDevices();
    }
  }

  Future<void> _saveMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('print_mode', mode);
  }

  List<ble.ScanResult> _bleDevices = [];

  Future<void> _loadDevices() async {
    setState(() {
      _isScanning = true;
    });
    try {
      if (_selectedMode == 'bluetooth_classic') {
        _devices = await PrintService.getPairedDevices();
      } else if (_selectedMode.startsWith('bluetooth_ble')) {
        _bleDevices = await S1ProPrintService.scanDevices();
      }
    } catch (e) {
      print('❌ Erreur: $e');
    }
    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _connectDevice(String address) async {
    setState(() {
      _isScanning = true;
    });
    try {
      bool success = false;
      if (_selectedMode == 'bluetooth_classic') {
        success = await PrintService.connectBluetooth(address);
      } else if (_selectedMode.startsWith('bluetooth_ble')) {
        success = await S1ProPrintService.connect(address);
      }
      setState(() {
        _isConnected = success;
        _selectedDevice = address;
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Connecté à l\'imprimante Bluetooth'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Échec de connexion'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur: $e');
    }
    setState(() {
      _isScanning = false;
    });
  }

  void _disconnectDevice() {
    PrintService.disconnectBluetooth();
    setState(() {
      _isConnected = false;
      _selectedDevice = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔌 Déconnecté'),
        backgroundColor: AppTheme.warningOrange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration d\'impression'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Mode d\'impression',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._printModes.map((mode) {
                      final isSelected = _selectedMode == mode;
                      return RadioListTile<String>(
                        title: Text(
                          _modeLabels[mode] ?? mode,
                          style: TextStyle(
                            color: isSelected ? AppTheme.primaryGold : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          _modeDescriptions[mode] ?? '',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        value: mode,
                        groupValue: _selectedMode,
                        activeColor: AppTheme.primaryGold,
                        onChanged: (value) {
                          setState(() {
                            _selectedMode = value!;
                            _saveMode(value);
                          });
                          if (mode == 'bluetooth') {
                            _loadDevices();
                          }
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_selectedMode.startsWith('bluetooth')) ...[
              Card(
                color: AppTheme.cardBackground,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                            color: _isConnected ? AppTheme.successGreen : AppTheme.primaryGold,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isConnected ? '✅ Connecté' : '🔗 Sélectionnez une imprimante',
                            style: TextStyle(
                              color: _isConnected ? AppTheme.successGreen : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_isConnected)
                            TextButton(
                              onPressed: _disconnectDevice,
                              child: const Text(
                                'Déconnecter',
                                style: TextStyle(color: AppTheme.dangerRed),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isScanning)
                        const Center(child: CircularProgressIndicator())
                      else if (_devices.isEmpty)
                        const Text(
                          'Aucune imprimante Bluetooth appairée trouvée',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        ..._devices.map((device) {
                          return Card(
                            color: Colors.grey[800],
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.print, color: AppTheme.primaryGold),
                              title: Text(
                                device.name ?? 'Imprimante',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                device.address ?? '',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              trailing: _selectedDevice == device.address && _isConnected
                                  ? const Icon(Icons.check_circle, color: AppTheme.successGreen)
                                  : ElevatedButton(
                                      onPressed: () => _connectDevice(device.address!),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryGold,
                                        foregroundColor: Colors.black,
                                      ),
                                      child: const Text('Connecter'),
                                    ),
                            ),
                          );
                        }).toList(),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _loadDevices,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Rafraîchir la liste'),
                      ),
                      const SizedBox(height: 12),
                      if (_isConnected)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await PrintService.printImageBluetooth(
                                ticketNumber: 'TEST-001',
                                date: DateTime.now().toString().substring(0, 19),
                                paymentMethod: 'Test',
                                total: 1000,
                                items: [
                                  {'name': 'Article Test', 'quantity': 2, 'total': 1000.0}
                                ],
                                shopName: 'BARMASTER TEST',
                                shopPhone: '0102030405',
                                shopAddress: 'Adresse de test',
                                shopSlogan: 'Test impression',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('✅ Test envoyé à l imprimante')),
                                );
                              }
                            },
                            icon: const Icon(Icons.print, color: Colors.black),
                            label: const Text('TESTER L IMPRESSION', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.all(14),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            if (_selectedMode == 'pdf')
              Card(
                color: AppTheme.cardBackground,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: AppTheme.primaryGold),
                          const SizedBox(width: 12),
                          const Text(
                            '📄 Mode PDF',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Le ticket sera affiché dans la console (simulation PDF)',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '💡 Version future : génération d\'un vrai fichier PDF',
                        style: TextStyle(
                          color: AppTheme.primaryGold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            Card(
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 Informations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Mode PDF : Affiche le ticket dans la console (simulation)',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    Text(
                      '• Mode Bluetooth : Nécessite une imprimante thermique appairée',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '⚠️ Le mode PDF sera amélioré dans une prochaine version',
                      style: TextStyle(color: AppTheme.warningOrange, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
