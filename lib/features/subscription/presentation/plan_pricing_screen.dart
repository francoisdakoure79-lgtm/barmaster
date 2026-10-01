import 'package:flutter/material.dart';
import '../../../core/database/models/plan.dart';
import '../../../shared/theme/app_theme.dart';

class PlanPricingScreen extends StatefulWidget {
  const PlanPricingScreen({super.key});
  @override
  State<PlanPricingScreen> createState() => _PlanPricingScreenState();
}

class _PlanPricingScreenState extends State<PlanPricingScreen> {
  @override
  Widget build(BuildContext context) {
    final plans = Plan.plans;

    return Scaffold(
      appBar: AppBar(title: const Text('Tarifs des abonnements')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plans.length,
        itemBuilder: (_, i) {
          final plan = plans[i];
          final monthlyCtrl = TextEditingController(text: plan.monthlyPrice.toStringAsFixed(0));
          final yearlyCtrl = TextEditingController(text: plan.yearlyPrice.toStringAsFixed(0));

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(plan.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.primaryGold.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: Text(plan.id.toUpperCase(), style: const TextStyle(color: AppTheme.primaryGold, fontSize: 11)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(plan.description, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: monthlyCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Prix mensuel (FCFA)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: yearlyCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Prix annuel (FCFA)', border: OutlineInputBorder()),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final monthly = double.tryParse(monthlyCtrl.text);
                      final yearly = double.tryParse(yearlyCtrl.text);
                      if (monthly != null && yearly != null && monthly > 0 && yearly > 0) {
                        Plan.updatePrice(plan.id, monthly, yearly);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('✅ ${plan.name}: $monthly F/mois - $yearly F/an')),
                        );
                        setState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.black),
                    child: const Text('ENREGISTRER'),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}
