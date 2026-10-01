import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/plan.dart';
import '../../../core/database/models/subscription.dart';
import '../../../shared/theme/app_theme.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Subscription> _subscriptions = [];
  bool _isLoading = true;
  bool _isYearly = false;

  // Contrôleurs pour le formulaire
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _clientEmailController = TextEditingController();
  String _selectedPlanId = 'starter';
  String _selectedPaymentMethod = 'Orange Money';
  int? _editingIndex;

  final List<String> _paymentMethods = [
    'Orange Money',
    'Moov Money',
    'Wave',
    'Carte Bancaire',
  ];

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  void _loadSubscriptions() {
    setState(() => _isLoading = true);
    try {
      _subscriptions = _db.getAllSubscriptions();
    } catch (e) {
      print('❌ Erreur: $e');
    }
    setState(() => _isLoading = false);
  }

  void _resetForm() {
    _clientNameController.clear();
    _clientPhoneController.clear();
    _clientEmailController.clear();
    setState(() {
      _editingIndex = null;
      _selectedPlanId = 'starter';
      _selectedPaymentMethod = 'Orange Money';
    });
  }

  void _editSubscription(int index) {
    final sub = _subscriptions[index];
    setState(() {
      _editingIndex = index;
      _clientNameController.text = sub.clientName ?? '';
      _clientPhoneController.text = sub.clientPhone ?? '';
      _clientEmailController.text = sub.clientEmail ?? '';
      _selectedPlanId = sub.planId;
      _selectedPaymentMethod = sub.paymentMethod;
    });
  }

  void _saveSubscription() {
    final clientName = _clientNameController.text.trim();
    final clientPhone = _clientPhoneController.text.trim();
    final clientEmail = _clientEmailController.text.trim();

    if (clientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le nom du client'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    final subscription = Subscription(
      planId: _selectedPlanId,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      isActive: true,
      paymentMethod: _selectedPaymentMethod,
      clientName: clientName,
      clientPhone: clientPhone,
      clientEmail: clientEmail,
    );

    if (_editingIndex != null) {
      _db.updateSubscription(_editingIndex!, subscription);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Abonnement mis à jour'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } else {
      _db.addSubscription(subscription);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Abonnement ajouté'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }

    _resetForm();
    _loadSubscriptions();
  }

  void _deleteSubscription(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Supprimer l\'abonnement'),
        content: Text(
          'Voulez-vous vraiment supprimer l\'abonnement de "${_subscriptions[index].clientName ?? 'client'}" ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              _db.deleteSubscription(index);
              Navigator.pop(context);
              _loadSubscriptions();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗑️ Abonnement supprimé'),
                  backgroundColor: AppTheme.warningOrange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Gestion des abonnements'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formulaire
                  Card(
                    color: AppTheme.cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editingIndex != null ? '✏️ Modifier l\'abonnement' : '➕ Ajouter un abonnement',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Client
                          TextField(
                            controller: _clientNameController,
                            decoration: const InputDecoration(
                              labelText: '👤 Nom du client *',
                              hintText: 'Ex: Jean Dupont',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Téléphone
                          TextField(
                            controller: _clientPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: '📞 Téléphone',
                              hintText: 'Ex: +225 07 07 07 07',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Email
                          TextField(
                            controller: _clientEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: '📧 Email',
                              hintText: 'Ex: client@email.com',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Plan
                          DropdownButtonFormField<String>(
                            value: _selectedPlanId,
                            decoration: const InputDecoration(
                              labelText: '📊 Plan',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.assignment),
                            ),
                            items: Plan.plans.map((plan) {
                              return DropdownMenuItem(
                                value: plan.id,
                                child: Text('${plan.name} - ${plan.monthlyPrice.toStringAsFixed(0)} FCFA/mois'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPlanId = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 12),

                          // Moyen de paiement
                          DropdownButtonFormField<String>(
                            value: _selectedPaymentMethod,
                            decoration: const InputDecoration(
                              labelText: '💳 Moyen de paiement',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.payment),
                            ),
                            items: _paymentMethods.map((method) {
                              return DropdownMenuItem(
                                value: method,
                                child: Text(method),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveSubscription,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGold,
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size(double.infinity, 50),
                                  ),
                                  child: Text(
                                    _editingIndex != null ? 'Mettre à jour' : 'Ajouter',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              if (_editingIndex != null) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _resetForm,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.grey,
                                      minimumSize: const Size(double.infinity, 50),
                                    ),
                                    child: const Text('Annuler'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Liste des abonnements
                  Card(
                    color: AppTheme.cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📋 Abonnements (${_subscriptions.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_subscriptions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Aucun abonnement',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            ..._subscriptions.asMap().entries.map((entry) {
                              final index = entry.key;
                              final sub = entry.value;
                              final plan = Plan.getPlan(sub.planId);
                              final isActive = sub.isActive && !sub.isExpired;

                              return Card(
                                color: isActive ? Colors.grey[800] : Colors.grey[800]!.withOpacity(0.5),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isActive ? AppTheme.successGreen.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        isActive ? Icons.check_circle : Icons.cancel,
                                        color: isActive ? AppTheme.successGreen : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    sub.clientName ?? 'Client',
                                    style: TextStyle(
                                      color: isActive ? Colors.white : Colors.grey[400],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${plan.name} - ${sub.paymentMethod}\n'
                                    'Début: ${_formatDate(sub.startDate)} - Fin: ${_formatDate(sub.endDate)}',
                                    style: TextStyle(
                                      color: isActive ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppTheme.primaryGold),
                                        onPressed: () => _editSubscription(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppTheme.dangerRed),
                                        onPressed: () => _deleteSubscription(index),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
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
