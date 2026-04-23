// lib/models/ledger_entry_model.dart

class LedgerEntryModel {
  final String? id;
  final String type;          // 'credit' | 'debit'
  final double amount;
  final String partyId;       // customer or supplier ID
  final String partyName;
  final String? referenceId;  // order ID or payment ID
  final String? referenceType; // 'order', 'payment', 'adjustment'
  final String description;
  final double runningBalance; // balance after this entry
  final DateTime date;
  final DateTime createdAt;

  LedgerEntryModel({
    this.id,
    required this.type,
    required this.amount,
    required this.partyId,
    required this.partyName,
    this.referenceId,
    this.referenceType,
    required this.description,
    this.runningBalance = 0.0,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'type':           type,
    'amount':         amount,
    'partyId':        partyId,
    'partyName':      partyName,
    'referenceId':    referenceId ?? '',
    'referenceType':  referenceType ?? '',
    'description':    description,
    'runningBalance': runningBalance,
    'date':           date.toIso8601String(),
    'createdAt':      createdAt.toIso8601String(),
  };

  factory LedgerEntryModel.fromMap(Map<String, dynamic> m, String docId) {
    return LedgerEntryModel(
      id:             docId,
      type:           m['type'] ?? 'debit',
      amount:         (m['amount'] ?? 0).toDouble(),
      partyId:        m['partyId'] ?? '',
      partyName:      m['partyName'] ?? '',
      referenceId:    m['referenceId'],
      referenceType:  m['referenceType'],
      description:    m['description'] ?? '',
      runningBalance: (m['runningBalance'] ?? 0).toDouble(),
      date:           DateTime.parse(
          m['date'] ?? DateTime.now().toIso8601String()),
      createdAt:      DateTime.parse(
          m['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  bool get isCredit => type == 'credit';
  bool get isDebit  => type == 'debit';
}
