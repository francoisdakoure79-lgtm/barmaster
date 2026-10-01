import 'package:flutter/foundation.dart';

class BarService extends ChangeNotifier {
  static final BarService _instance = BarService._internal();
  factory BarService() => _instance;
  BarService._internal();

  String? barName;
  String? barAddress;
  String? barPhone;
  String? barEmail;
  String? barManager;
  String? barSlogan;
  String? barLogo;

  bool get hasBar => barName != null && barName!.isNotEmpty;

  void setBarInfo(Map<String, dynamic> data) {
    barName = data['name'] ?? barName;
    barAddress = data['address'] ?? barAddress;
    barPhone = data['phone'] ?? barPhone;
    barEmail = data['email'] ?? barEmail;
    barManager = data['manager'] ?? barManager;
    barSlogan = data['slogan'] ?? barSlogan;
    barLogo = data['logo'] ?? barLogo;
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
    'name': barName,
    'address': barAddress,
    'phone': barPhone,
    'email': barEmail,
    'manager': barManager,
    'slogan': barSlogan,
    'logo': barLogo,
  };

  String get headerTicket => '''
╔══════════════════════════════╗
║  ${barName ?? 'BARMASTER'}
║  ${barAddress ?? ''}
║  Tél: ${barPhone ?? ''}
║  ${barSlogan ?? ''}
╚══════════════════════════════╝
''';

  String get footerTicket => '''
────────────────────────────────
     Merci de votre visite !
  ${barName ?? 'BARMASTER'}
  Tél: ${barPhone ?? ''}
────────────────────────────────
''';
}
