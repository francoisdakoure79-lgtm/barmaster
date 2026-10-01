import '../../../core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/text_report_service.dart';
import '../../../shared/theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isGenerating = false;
  String _reportContent = '';
  bool _showReport = false;
  String _barName = AuthService.barName;
  String _debugBarName = AuthService.barName;

  @override
  void initState() {
    print('🏪 Bar name pour rapport: $_barName');
    super.initState();
    _loadBarConfig();
  }

  void _loadBarConfig() {
    try {
      final config = _db.getBarConfig();
    } catch (e) {
      print('⚠️ Erreur chargement config: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _openReportsFolder,
          ),
        ],
      ),
      body: _showReport && _reportContent.isNotEmpty
          ? _buildReportView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Entête avec le nom du bar
                  Card(
                    color: AppTheme.cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.store, color: AppTheme.primaryGold),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '🏪 $_barName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rapport Journalier
                  Card(
                    color: AppTheme.cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.today, color: AppTheme.primaryGold),
                              const SizedBox(width: 12),
                              const Text(
                                '📅 Rapport Journalier',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Génère un rapport détaillé (.txt) pour une date spécifique',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.calendar_today, color: AppTheme.primaryGold),
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() => _selectedDate = date);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _isGenerating
                              ? const Center(child: CircularProgressIndicator())
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await _generateReport(
                                        () => TextReportService.generateDailyReport(_selectedDate),
                                        'rapport_journalier_${_selectedDate.year}${_selectedDate.month.toString().padLeft(2, '0')}${_selectedDate.day.toString().padLeft(2, '0')}',
                                      );
                                    },
                                    icon: const Icon(Icons.text_snippet),
                                    label: const Text('Générer le rapport .txt'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGold,
                                      foregroundColor: Colors.black,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rapport Mensuel
                  Card(
                    color: AppTheme.cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, color: AppTheme.primaryGold),
                              const SizedBox(width: 12),
                              const Text(
                                '📊 Rapport Mensuel',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Génère un rapport récapitulatif (.txt) pour un mois',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_left, color: AppTheme.primaryGold),
                                      onPressed: () {
                                        if (_selectedMonth > 1) {
                                          setState(() => _selectedMonth--);
                                        } else {
                                          setState(() {
                                            _selectedMonth = 12;
                                            _selectedYear--;
                                          });
                                        }
                                      },
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${_getMonthName(_selectedMonth)} $_selectedYear',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_right, color: AppTheme.primaryGold),
                                      onPressed: () {
                                        if (_selectedMonth < 12) {
                                          setState(() => _selectedMonth++);
                                        } else {
                                          setState(() {
                                            _selectedMonth = 1;
                                            _selectedYear++;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _isGenerating
                              ? const Center(child: CircularProgressIndicator())
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await _generateReport(
                                        () => TextReportService.generateMonthlyReport(_selectedYear, _selectedMonth),
                                        'rapport_mensuel_${_selectedYear}_${_selectedMonth.toString().padLeft(2, '0')}',
                                      );
                                    },
                                    icon: const Icon(Icons.text_snippet),
                                    label: const Text('Générer le rapport .txt'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGold,
                                      foregroundColor: Colors.black,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rapport Annuel
                  Card(
                    color: AppTheme.cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_view_month, color: AppTheme.primaryGold),
                              const SizedBox(width: 12),
                              const Text(
                                '📈 Rapport Annuel (Cumul)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Génère un bilan complet (.txt) pour toute une année',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_left, color: AppTheme.primaryGold),
                                      onPressed: () {
                                        setState(() => _selectedYear--);
                                      },
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Année $_selectedYear',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_right, color: AppTheme.primaryGold),
                                      onPressed: () {
                                        setState(() => _selectedYear++);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _isGenerating
                              ? const Center(child: CircularProgressIndicator())
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await _generateReport(
                                        () => TextReportService.generateYearlyReport(_selectedYear),
                                        'rapport_annuel_$_selectedYear',
                                      );
                                    },
                                    icon: const Icon(Icons.text_snippet),
                                    label: const Text('Générer le rapport .txt'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGold,
                                      foregroundColor: Colors.black,
                                    ),
                                  ),
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

  Widget _buildReportView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _reportContent,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[900],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  _showReport = false;
                  _reportContent = '';
                }),
                icon: const Icon(Icons.close),
                label: const Text('Fermer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _shareReport(),
                icon: const Icon(Icons.share),
                label: const Text('Partager'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.black,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _saveReport(),
                icon: const Icon(Icons.save),
                label: const Text('Sauvegarder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _generateReport(Future<String> Function() generator, String filename) async {
    setState(() => _isGenerating = true);
    try {
      final content = await generator();
      await TextReportService.saveReport(content, filename);
      setState(() {
        _reportContent = content;
        _showReport = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Rapport "$filename.txt" généré !'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
    setState(() => _isGenerating = false);
  }

  Future<void> _shareReport() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📁 Rapport disponible dans: ${appDocDir.path}/rapports/'),
        backgroundColor: AppTheme.primaryGold,
      ),
    );
  }

  Future<void> _saveReport() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${appDocDir.path}/rapports/rapport_$timestamp.txt');
      await file.writeAsString(_reportContent);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Rapport sauvegardé: ${file.path}'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  Future<void> _openReportsFolder() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${appDocDir.path}/rapports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }
      await Process.run('xdg-open', [reportsDir.path]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Impossible d\'ouvrir le dossier: $e'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }
}
