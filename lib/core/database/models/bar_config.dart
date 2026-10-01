class BarConfig {
  String name;
  String address;
  String phone;
  String email;
  String currency;
  String logoPath;
  String slogan;
  String manager;

  BarConfig({
    this.name = 'Mon Bar',
    this.address = 'Votre adresse',
    this.phone = '+225 00 00 00 00',
    this.email = 'contact@monbar.com',
    this.currency = 'FCFA',
    this.logoPath = '',
    this.slogan = 'Le meilleur du terroir',
    this.manager = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'currency': currency,
      'logoPath': logoPath,
      'slogan': slogan,
      'manager': manager,
    };
  }

  factory BarConfig.fromJson(Map<String, dynamic> json) {
    return BarConfig()
      ..name = json['name'] ?? 'Mon Bar'
      ..address = json['address'] ?? 'Votre adresse'
      ..phone = json['phone'] ?? '+225 00 00 00 00'
      ..email = json['email'] ?? 'contact@monbar.com'
      ..currency = json['currency'] ?? 'FCFA'
      ..logoPath = json['logoPath'] ?? ''
      ..slogan = json['slogan'] ?? 'Le meilleur du terroir'
      ..manager = json['manager'] ?? '';
  }
}
