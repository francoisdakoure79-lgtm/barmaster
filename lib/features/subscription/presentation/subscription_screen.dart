import 'package:flutter/material.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../main.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _keyCtrl = TextEditingController();
  int _selectedDuration = 30;
  String _generatedKey = '';
  String _message = '';

  final _durations = [7, 10, 15, 30, 60, 90, 180, 365];

  @override
  Widget build(BuildContext context) {
    final isExpired = SubscriptionService.isExpired();
    final remaining = SubscriptionService.getRemainingDays();

    return Scaffold(
      appBar: AppBar(title: const Text('Abonnement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Statut actuel
          Card(
            color: isExpired ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(isExpired ? Icons.lock : Icons.check_circle, color: isExpired ? Colors.red : Colors.green, size: 30),
                const SizedBox(width: 12),
                Expanded(child: Text(isExpired ? 'ABONNEMENT EXPIRE' : 'Abonnement actif\n$remaining', style: TextStyle(color: isExpired ? Colors.red : Colors.green, fontSize: 16, fontWeight: FontWeight.bold))),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // Section Super Admin : générer clé
          if (AuthService.getCurrentUser()?.isSuperAdmin ?? false) ...[
            const Text('GENERER UNE CLE', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedDuration,
              decoration: const InputDecoration(labelText: 'Duree de l abonnement'),
              items: _durations.map((d) => DropdownMenuItem(value: d, child: Text('$d jours'))).toList(),
              onChanged: (v) => setState(() => _selectedDuration = v!),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final key = await SubscriptionService.generateKey(durationDays: _selectedDuration);
                setState(() { _generatedKey = key; _message = '✅ Cle generee: $key'; });
              },
              icon: const Icon(Icons.vpn_key),
              label: const Text('GENERER'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.black, padding: const EdgeInsets.all(14)),
            ),
            if (_generatedKey.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_generatedKey, style: const TextStyle(fontSize: 22, letterSpacing: 6, fontWeight: FontWeight.bold, color: AppTheme.primaryGold), textAlign: TextAlign.center),
              ),
            const Divider(height: 30),
          ],

          // Activation par clé
          const Text('ACTIVER', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _keyCtrl,
            maxLength: 12,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, letterSpacing: 6, color: Colors.white),
            decoration: InputDecoration(hintText: '000000000000', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey[800], counterText: ''),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              final result = await SubscriptionService.activateSubscription(_keyCtrl.text.trim(), barName: AuthService.barName);
              setState(() => _message = result);
              if (result.startsWith('✅')) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
            child: const Text('ACTIVER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          if (_message.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message, style: const TextStyle(fontSize: 14), textAlign: TextAlign.center)),
        ]),
      ),
    );
  }
}
