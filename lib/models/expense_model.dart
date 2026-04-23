// lib/models/expense_model.dart

class ExpenseModel {
  final String? id;
  final String category;     // Rent, Salary, Transport, Utilities, etc.
  final double amount;
  final String description;
  final String? receiptImagePath;
  final String paymentMethod; // cash, upi, bank_transfer
  final DateTime date;
  final DateTime createdAt;

  ExpenseModel({
    this.id,
    required this.category,
    required this.amount,
    required this.description,
    this.receiptImagePath,
    this.paymentMethod = 'cash',
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'category':         category,
    'amount':           amount,
    'description':      description,
    'receiptImagePath': receiptImagePath ?? '',
    'paymentMethod':    paymentMethod,
    'date':             date.toIso8601String(),
    'createdAt':        createdAt.toIso8601String(),
  };

  factory ExpenseModel.fromMap(Map<String, dynamic> m, String docId) {
    return ExpenseModel(
      id:               docId,
      category:         m['category'] ?? 'General',
      amount:           (m['amount'] ?? 0).toDouble(),
      description:      m['description'] ?? '',
      receiptImagePath: m['receiptImagePath'],
      paymentMethod:    m['paymentMethod'] ?? 'cash',
      date:             DateTime.parse(
          m['date'] ?? DateTime.now().toIso8601String()),
      createdAt:        DateTime.parse(
          m['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
