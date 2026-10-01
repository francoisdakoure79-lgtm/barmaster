class Product {
  int id;
  String name;
  int categoryId;
  double purchasePrice;
  double sellingPrice;
  int minStockThreshold;
  int currentStock;
  String unit;
  String? barcode;

  Product({
    required this.id, required this.name, required this.categoryId,
    required this.purchasePrice, required this.sellingPrice,
    this.minStockThreshold = 10, this.currentStock = 0,
    this.unit = 'unité', this.barcode,
  });

  bool get isCritical => currentStock == 0;
  bool get isWarning => currentStock > 0 && currentStock <= minStockThreshold;
  bool get isOk => currentStock > minStockThreshold;

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'categoryId': categoryId,
    'purchasePrice': purchasePrice, 'sellingPrice': sellingPrice,
    'minStockThreshold': minStockThreshold, 'currentStock': currentStock,
    'unit': unit, 'barcode': barcode,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'], name: json['name'], categoryId: json['categoryId'],
    purchasePrice: (json['purchasePrice'] as num).toDouble(),
    sellingPrice: (json['sellingPrice'] as num).toDouble(),
    minStockThreshold: json['minStockThreshold'] ?? 10,
    currentStock: json['currentStock'] ?? 0,
    unit: json['unit'] ?? 'unité',
    barcode: json['barcode'],
  );
}

class Sale {
  int id;
  String ticketNumber;
  double totalAmount;
  int saleDate;
  String paymentMethod;
  String barName; // ✅ Ajouté pour isoler par bar
  String cashierName; // ✅ Qui a fait la vente

  Sale({
    required this.id, required this.ticketNumber,
    required this.totalAmount, required this.saleDate,
    required this.paymentMethod,
    this.barName = '', this.cashierName = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'ticketNumber': ticketNumber,
    'totalAmount': totalAmount, 'saleDate': saleDate,
    'paymentMethod': paymentMethod,
    'barName': barName, 'cashierName': cashierName,
  };

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
    id: json['id'], ticketNumber: json['ticketNumber'],
    totalAmount: (json['totalAmount'] as num).toDouble(),
    saleDate: json['saleDate'], paymentMethod: json['paymentMethod'] ?? 'Espèces',
    barName: json['barName'] ?? '', cashierName: json['cashierName'] ?? '',
  );
}

class SaleItem {
  int id;
  int saleId;
  int productId;
  int quantity;
  double unitPrice;
  double totalPrice;

  SaleItem({
    required this.id, required this.saleId, required this.productId,
    required this.quantity, required this.unitPrice, required this.totalPrice,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'saleId': saleId, 'productId': productId,
    'quantity': quantity, 'unitPrice': unitPrice, 'totalPrice': totalPrice,
  };

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
    id: json['id'], saleId: json['saleId'], productId: json['productId'],
    quantity: json['quantity'], unitPrice: (json['unitPrice'] as num).toDouble(),
    totalPrice: (json['totalPrice'] as num).toDouble(),
  );
}
