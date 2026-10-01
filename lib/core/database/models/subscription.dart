class Subscription {
  final String planId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String paymentMethod;
  final String? clientName;
  final String? clientPhone;
  final String? clientEmail;

  Subscription({
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.paymentMethod,
    this.clientName,
    this.clientPhone,
    this.clientEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'paymentMethod': paymentMethod,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientEmail': clientEmail,
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      planId: json['planId'] ?? 'starter',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isActive: json['isActive'] ?? false,
      paymentMethod: json['paymentMethod'] ?? 'Orange Money',
      clientName: json['clientName'],
      clientPhone: json['clientPhone'],
      clientEmail: json['clientEmail'],
    );
  }

  bool get isExpired => endDate.isBefore(DateTime.now());
  bool get isTrial => paymentMethod == 'Essai gratuit' && isActive;
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
}
