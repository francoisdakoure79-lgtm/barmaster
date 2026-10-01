class Plan {
  final String id;
  final String name;
  final String description;
  double monthlyPrice;
  double yearlyPrice;
  final List<String> features;
  final int maxUsers;
  final bool hasCloudSync;
  final bool hasReports;
  final bool hasPrinting;
  final bool isActive;

  Plan({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    required this.maxUsers,
    required this.hasCloudSync,
    required this.hasReports,
    required this.hasPrinting,
    this.isActive = true,
  });

  static List<Plan> _plans = [];

  static List<Plan> get plans {
    if (_plans.isEmpty) _plans = _defaultPlans();
    return _plans;
  }

  static void updatePrice(String planId, double monthlyPrice, double yearlyPrice) {
    final plan = plans.firstWhere((p) => p.id == planId);
    plan.monthlyPrice = monthlyPrice;
    plan.yearlyPrice = yearlyPrice;
  }

  static List<Plan> _defaultPlans() => [
    Plan(id: 'starter', name: 'Starter', description: 'Pour les petits bars', monthlyPrice: 5000, yearlyPrice: 48000, maxUsers: 2, hasCloudSync: false, hasReports: true, hasPrinting: false, features: ['📦 Gestion inventaire', '🛒 Ventes', '🔔 Alertes stock', '📊 Statistiques', '📄 Rapports PDF', '👥 2 utilisateurs']),
    Plan(id: 'pro', name: 'Pro', description: 'Pour les bars en croissance', monthlyPrice: 10000, yearlyPrice: 96000, maxUsers: 5, hasCloudSync: false, hasReports: true, hasPrinting: true, features: ['📦 Gestion inventaire', '🛒 Ventes', '🔔 Alertes stock', '📊 Statistiques', '📄 Rapports PDF', '🖨️ Impression', '👥 5 utilisateurs', '📋 Gestion des catégories']),
    Plan(id: 'premium', name: 'Premium', description: 'Pour les grands établissements', monthlyPrice: 15000, yearlyPrice: 144000, maxUsers: 999, hasCloudSync: true, hasReports: true, hasPrinting: true, features: ['📦 Gestion inventaire', '🛒 Ventes', '🔔 Alertes stock', '📊 Statistiques avancées', '📄 Rapports PDF', '🖨️ Impression', '☁️ Synchronisation Nextcloud', '👥 Utilisateurs illimités', '📱 Support prioritaire', '🔒 Données sécurisées']),
  ];

  static Plan getPlan(String id) => plans.firstWhere((p) => p.id == id, orElse: () => plans.first);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'monthlyPrice': monthlyPrice, 'yearlyPrice': yearlyPrice};

  bool get isStarter => id == 'starter';
  bool get isPro => id == 'pro';
  bool get isPremium => id == 'premium';
}
