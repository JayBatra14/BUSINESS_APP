// lib/services/order_service.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart';
import 'product_service.dart';
import 'customer_service.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final _uuid = const Uuid();
  final _productService  = ProductService();
  final _customerService = CustomerService();
  Box get _box => Hive.box('orders');

  /// Generate next order number (e.g., ORD-00001)
  String _nextOrderNumber() {
    final count = _box.length + 1;
    return 'ORD-${count.toString().padLeft(5, '0')}';
  }

  /// Create a new order
  Future<String> createOrder(OrderModel order) async {
    final id = _uuid.v4();
    final data = order.toMap();
    data['id'] = id;
    await _box.put(id, data);

    // Deduct stock for each item
    for (final item in order.items) {
      await _productService.deductStock(item.productId, item.quantity);
    }

    // Update customer balance if there's a balance due
    if (order.customerId != null && order.customerId!.isNotEmpty) {
      final customer = _customerService.getCustomer(order.customerId!);
      if (customer != null) {
        final newBalance = customer.balance + order.balanceDue;
        await _customerService.updateBalance(order.customerId!, newBalance);
      }
    }

    return id;
  }

  /// Get order by ID
  OrderModel? getOrder(String id) {
    final data = _box.get(id);
    if (data == null) return null;
    return OrderModel.fromMap(Map<String, dynamic>.from(data), id);
  }

  /// Get all orders (newest first)
  List<OrderModel> getAllOrders() {
    return _box.keys.map((key) {
      final data = _box.get(key);
      return OrderModel.fromMap(
          Map<String, dynamic>.from(data), key.toString());
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get orders by status
  List<OrderModel> getOrdersByStatus(String status) {
    return getAllOrders().where((o) => o.status == status).toList();
  }

  /// Get orders by customer
  List<OrderModel> getOrdersByCustomer(String customerId) {
    return getAllOrders()
        .where((o) => o.customerId == customerId)
        .toList();
  }

  /// Get today's orders
  List<OrderModel> getTodayOrders() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return getAllOrders().where((o) {
      final orderDate = DateTime(
          o.createdAt.year, o.createdAt.month, o.createdAt.day);
      return orderDate == today;
    }).toList();
  }

  /// Get today's total sales
  double getTodaySales() {
    return getTodayOrders().fold(0.0, (sum, o) => sum + o.grandTotal);
  }

  /// Get sales for last N days
  List<double> getSalesForLastDays(int days) {
    final now = DateTime.now();
    final result = <double>[];
    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final daySales = getAllOrders().where((o) {
        final orderDate = DateTime(
            o.createdAt.year, o.createdAt.month, o.createdAt.day);
        return orderDate == date;
      }).fold(0.0, (sum, o) => sum + o.grandTotal);
      result.add(daySales);
    }
    return result;
  }

  /// Update order status
  Future<void> updateOrderStatus(String id, String newStatus) async {
    final data = _box.get(id);
    if (data == null) return;
    final map = Map<String, dynamic>.from(data);
    map['status'] = newStatus;
    await _box.put(id, map);
  }

  /// Record payment
  Future<void> recordPayment(String id, double amount, String method) async {
    final data = _box.get(id);
    if (data == null) return;
    final map = Map<String, dynamic>.from(data);
    final currentPaid = (map['amountPaid'] ?? 0).toDouble();
    final grandTotal  = (map['grandTotal'] ?? 0).toDouble();
    final newPaid     = currentPaid + amount;
    
    map['amountPaid']    = newPaid;
    map['paymentMethod'] = method;
    map['paymentStatus'] = newPaid >= grandTotal ? 'paid' : 'partial';
    await _box.put(id, map);

    // Update customer balance
    final customerId = map['customerId'] ?? '';
    if (customerId.isNotEmpty) {
      final customer = _customerService.getCustomer(customerId);
      if (customer != null) {
        await _customerService.updateBalance(
            customerId, customer.balance - amount);
      }
    }
  }

  /// Delete order
  Future<void> deleteOrder(String id) async {
    await _box.delete(id);
  }

  /// Get new order number
  String getNextOrderNumber() => _nextOrderNumber();

  /// Get order count
  int get count => _box.length;

  /// Get total revenue (all time)
  double get totalRevenue =>
      getAllOrders().fold(0.0, (sum, o) => sum + o.grandTotal);
}
