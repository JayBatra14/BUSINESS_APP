// lib/services/expense_service.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';

class ExpenseService {
  static final ExpenseService _instance = ExpenseService._internal();
  factory ExpenseService() => _instance;
  ExpenseService._internal();

  final _uuid = const Uuid();
  Box get _box => Hive.box('expenses');

  /// Add expense
  Future<String> addExpense(ExpenseModel expense) async {
    final id = _uuid.v4();
    final data = expense.toMap();
    data['id'] = id;
    await _box.put(id, data);
    return id;
  }

  /// Get all expenses (newest first)
  List<ExpenseModel> getAllExpenses() {
    return _box.keys.map((key) {
      final data = _box.get(key);
      return ExpenseModel.fromMap(
          Map<String, dynamic>.from(data), key.toString());
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get today's expenses
  double getTodayExpenses() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return getAllExpenses().where((e) {
      final expDate = DateTime(e.date.year, e.date.month, e.date.day);
      return expDate == today;
    }).fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Get expenses by category
  Map<String, double> getExpensesByCategory() {
    final map = <String, double>{};
    for (final e in getAllExpenses()) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  /// Get total expenses for a month
  double getMonthlyTotal(int year, int month) {
    return getAllExpenses()
        .where((e) => e.date.year == year && e.date.month == month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Update expense
  Future<void> updateExpense(String id, ExpenseModel expense) async {
    final data = expense.toMap();
    data['id'] = id;
    await _box.put(id, data);
  }

  /// Delete expense
  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
  }

  int get count => _box.length;
}
