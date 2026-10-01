class User {
  int id;
  String username;
  String password;
  String fullName;
  String role;
  bool isActive;
  int createdAt;
  int? lastLogin;
  int? barId;
  String? barName;
  String? barAddress;
  String? barPhone;
  String? barEmail;
  String? barManager;
  String? barCode;

  User({
    required this.id, required this.username, required this.password,
    required this.fullName, required this.role, this.isActive = true,
    required this.createdAt, this.lastLogin, this.barId, this.barName,
    this.barAddress, this.barPhone, this.barEmail, this.barManager, this.barCode,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'username': username, 'password': password, 'fullName': fullName,
    'role': role, 'isActive': isActive, 'createdAt': createdAt, 'lastLogin': lastLogin,
    'barId': barId, 'barName': barName, 'barAddress': barAddress, 'barPhone': barPhone,
    'barEmail': barEmail, 'barManager': barManager, 'barCode': barCode,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'], username: json['username'], password: json['password'],
    fullName: json['fullName'], role: json['role'], isActive: json['isActive'] ?? true,
    createdAt: json['createdAt'], lastLogin: json['lastLogin'], barId: json['barId'],
    barName: json['barName'], barAddress: json['barAddress'], barPhone: json['barPhone'],
    barEmail: json['barEmail'], barManager: json['barManager'], barCode: json['barCode'],
  );

  factory User.fromMap(Map<String, dynamic> map) => User.fromJson(map);

  bool get isAdmin => role == 'admin';
  bool get isCaissier => role == 'caissier';
  bool get isServeur => role == 'serveur';
  bool get isSuperAdmin => role == 'superadmin';

  // ✅ Permissions
  bool get canAccessSales => isCaissier || isServeur;
  bool get canAccessInventory => isAdmin || isCaissier;
  bool get canAccessPurchases => isAdmin || isCaissier;
  bool get canAccessStats => isAdmin || isCaissier;
  bool get canAccessSettings => isSuperAdmin;
  bool get canAccessReports => isAdmin || isCaissier;
  bool get canAccessUsers => isAdmin || isSuperAdmin;
  bool get canAccessCategories => isAdmin || isCaissier;
  bool get canAccessPrinting => isAdmin || isCaissier;
  bool get canAccessSync => isAdmin;

  bool get hasBar => barName != null && barName!.isNotEmpty;
}
