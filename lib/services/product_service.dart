// lib/services/product_service.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final _uuid = const Uuid();
  Box get _box => Hive.box('products');

  /// Save a new product
  Future<String> addProduct(ProductModel product) async {
    final id = _uuid.v4();
    final data = product.toMap();
    data['id'] = id;
    await _box.put(id, data);
    return id;
  }

  /// Get a product by ID
  ProductModel? getProduct(String id) {
    final data = _box.get(id);
    if (data == null) return null;
    return ProductModel.fromMap(Map<String, dynamic>.from(data), id);
  }

  /// Get all products
  List<ProductModel> getAllProducts() {
    return _box.keys.map((key) {
      final data = _box.get(key);
      return ProductModel.fromMap(
          Map<String, dynamic>.from(data), key.toString());
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Search products by name
  List<ProductModel> searchProducts(String query) {
    final q = query.toLowerCase();
    return getAllProducts()
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            (p.sku ?? '').toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q))
        .toList();
  }

  /// Get products by category
  List<ProductModel> getByCategory(String category) {
    return getAllProducts()
        .where((p) => p.category == category)
        .toList();
  }

  /// Get low stock products
  List<ProductModel> getLowStockProducts() {
    return getAllProducts().where((p) => p.isLowStock).toList();
  }

  /// Update product
  Future<void> updateProduct(String id, ProductModel product) async {
    final data = product.toMap();
    data['id'] = id;
    await _box.put(id, data);
  }

  /// Update stock quantity
  Future<void> updateStock(String id, double newQty) async {
    final data = _box.get(id);
    if (data == null) return;
    final map = Map<String, dynamic>.from(data);
    map['stockQty'] = newQty;
    await _box.put(id, map);
  }

  /// Deduct stock (after sale)
  Future<void> deductStock(String id, double qty) async {
    final product = getProduct(id);
    if (product == null) return;
    final newQty = product.stockQty - qty;
    await updateStock(id, newQty < 0 ? 0 : newQty);
  }

  /// Delete product
  Future<void> deleteProduct(String id) async {
    await _box.delete(id);
  }

  /// Get all unique categories
  List<String> getAllCategories() {
    final cats = getAllProducts().map((p) => p.category).toSet().toList();
    cats.sort();
    return cats;
  }

  /// Get product count
  int get count => _box.length;
}
