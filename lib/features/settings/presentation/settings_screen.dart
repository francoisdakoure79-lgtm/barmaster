import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../print_settings/presentation/print_settings_screen.dart';
import '../../team_bar/presentation/team_bar_screen.dart';
import '../../sync/presentation/supabase_sync_screen.dart';
import '../../subscription/presentation/subscription_screen.dart';
import '../../history/presentation/history_screen.dart';
import 'auto_backup_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.getCurrentUser();
    final isSuperAdmin = user?.isSuperAdmin ?? false;
    final isAdmin = user?.isAdmin ?? false;
    final isCaissier = user?.isCaissier ?? false;
    final isServeur = user?.isServeur ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Parametres')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (isSuperAdmin) ...[
          _card(context, Icons.vpn_key, '🔑 Abonnement', 'Gerer, generer cles, activer', const SubscriptionScreen()),
          _card(context, Icons.people, '👥 Equipe & Bar', 'Gerer utilisateurs et bar', const TeamBarScreen()),
          _card(context, Icons.sync, '🔄 Synchro Supabase', 'Synchroniser', const SupabaseSyncScreen()),
          _card(context, Icons.backup, '💾 Sauvegarde auto', 'Configurer', const AutoBackupSettingsScreen()),
          _card(context, Icons.history, '📋 Historique ventes', 'Toutes les ventes', const HistoryScreen()),
          _card(context, Icons.bar_chart, '📊 Rapports', 'Journaliers, mensuels', const ReportsScreen()),
          _card(context, Icons.category, '📂 Categories', 'Gerer categories', const CategoriesScreen()),
          _card(context, Icons.print, '🖨️ Impression', 'Configurer imprimante', const PrintSettingsScreen()),
          _card(context, Icons.info, 'ℹ️ A propos', 'BarMaster v1.0', null),
        ],
        if (isAdmin && !isSuperAdmin) ...[
          _card(context, Icons.bar_chart, '📊 Rapports', 'Journaliers, mensuels', const ReportsScreen()),
          _card(context, Icons.history, '📋 Ventes du jour', 'Historique', const HistoryScreen()),
          _card(context, Icons.people, '👥 Utilisateurs', 'Mon personnel', const TeamBarScreen()),
          _card(context, Icons.sync, '🔄 Synchro Supabase', 'Synchroniser', const SupabaseSyncScreen()),
          _card(context, Icons.category, '📂 Categories', 'Gerer categories', const CategoriesScreen()),
          _card(context, Icons.print, '🖨️ Impression', 'Configurer imprimante', const PrintSettingsScreen()),
          _card(context, Icons.info, 'ℹ️ A propos', 'BarMaster v1.0', null),
        ],
        if (isCaissier) ...[
          _card(context, Icons.bar_chart, '📊 Rapports', 'Journaliers, mensuels', const ReportsScreen()),
          _card(context, Icons.history, '📋 Ventes du jour', 'Historique', const HistoryScreen()),
          _card(context, Icons.category, '📂 Categories', 'Gerer categories', const CategoriesScreen()),
          _card(context, Icons.print, '🖨️ Impression', 'Configurer imprimante', const PrintSettingsScreen()),
          _card(context, Icons.info, 'ℹ️ A propos', 'BarMaster v1.0', null),
        ],
        if (isServeur) ...[
          _card(context, Icons.history, '📋 Ventes du jour', 'Historique', const HistoryScreen()),
          _card(context, Icons.print, '🖨️ Impression', 'Configurer imprimante', const PrintSettingsScreen()),
          _card(context, Icons.info, 'ℹ️ A propos', 'BarMaster v1.0', null),
        ],
      ]),
    );
  }

  Widget _card(BuildContext context, IconData icon, String title, String subtitle, Widget? screen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryGold),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: screen != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)) : null,
      ),
    );
  }
}
