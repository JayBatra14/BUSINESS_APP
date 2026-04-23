// lib/models/product_model.dart

class ProductModel {
  final String? id;
  final String name;
  final String? sku;
  final String category;
  final double sellingPrice;
  final double? costPrice;
  final double stockQty;
  final String unit;         // pcs, kg, litre, box, etc.
  final double taxPercent;   // GST %
  final String? hsnCode;
  final String? barcode;
  final String? description;
  final String? imagePath;
  final double lowStockAlert; // alert when stock falls below this
  final DateTime createdAt;

  ProductModel({
    this.id,
    required this.name,
    this.sku,
    required this.category,
    required this.sellingPrice,
    this.costPrice,
    required this.stockQty,
    this.unit = 'pcs',
    this.taxPercent = 0.0,
    this.hsnCode,
    this.barcode,
    this.description,
    this.imagePath,
    this.lowStockAlert = 5.0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'name':          name,
    'sku':           sku ?? '',
    'category':      category,
    'sellingPrice':  sellingPrice,
    'costPrice':     costPrice ?? 0.0,
    'stockQty':      stockQty,
    'unit':          unit,
    'taxPercent':    taxPercent,
    'hsnCode':       hsnCode ?? '',
    'barcode':       barcode ?? '',
    'description':   description ?? '',
    'imagePath':     imagePath ?? '',
    'lowStockAlert': lowStockAlert,
    'createdAt':     createdAt.toIso8601String(),
  };

  factory ProductModel.fromMap(Map<String, dynamic> m, String docId) {
    return ProductModel(
      id:            docId,
      name:          m['name'] ?? '',
      sku:           m['sku'],
      category:      m['category'] ?? 'General',
      sellingPrice:  (m['sellingPrice'] ?? 0).toDouble(),
      costPrice:     (m['costPrice'] ?? 0).toDouble(),
      stockQty:      (m['stockQty'] ?? 0).toDouble(),
      unit:          m['unit'] ?? 'pcs',
      taxPercent:    (m['taxPercent'] ?? 0).toDouble(),
      hsnCode:       m['hsnCode'],
      barcode:       m['barcode'],
      description:   m['description'],
      imagePath:     m['imagePath'],
      lowStockAlert: (m['lowStockAlert'] ?? 5).toDouble(),
      createdAt:     DateTime.parse(
          m['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  bool get isLowStock => stockQty <= lowStockAlert;
  double get profit => sellingPrice - (costPrice ?? 0);
}
