// lib/services/customer_service.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/customer_model.dart';

class CustomerService {
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  final _uuid = const Uuid();
  Box get _box => Hive.box('customers');

  /// Add a new customer
  Future<String> addCustomer(CustomerModel customer) async {
    final id = _uuid.v4();
    final data = customer.toMap();
    data['id'] = id;
    await _box.put(id, data);
    return id;
  }

  /// Get customer by ID
  CustomerModel? getCustomer(String id) {
    final data = _box.get(id);
    if (data == null) return null;
    return CustomerModel.fromMap(Map<String, dynamic>.from(data), id);
  }

  /// Get all customers
  List<CustomerModel> getAllCustomers() {
    return _box.keys.map((key) {
      final data = _box.get(key);
      return CustomerModel.fromMap(
          Map<String, dynamic>.from(data), key.toString());
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Search customers by name or phone
  List<CustomerModel> searchCustomers(String query) {
    final q = query.toLowerCase();
    return getAllCustomers()
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.phoneNumbers.any((p) => p.contains(q)) ||
            (c.email ?? '').toLowerCase().contains(q))
        .toList();
  }

  /// Update customer
  Future<void> updateCustomer(String id, CustomerModel customer) async {
    final data = customer.toMap();
    data['id'] = id;
    await _box.put(id, data);
  }

  /// Update customer balance
  Future<void> updateBalance(String id, double newBalance) async {
    final data = _box.get(id);
    if (data == null) return;
    final map = Map<String, dynamic>.from(data);
    map['balance'] = newBalance;
    await _box.put(id, map);
  }

  /// Delete customer
  Future<void> deleteCustomer(String id) async {
    await _box.delete(id);
  }

  /// Get customers with outstanding balance
  List<CustomerModel> getCustomersWithBalance() {
    return getAllCustomers().where((c) => c.balance != 0).toList();
  }

  /// Get customer count
  int get count => _box.length;
}
