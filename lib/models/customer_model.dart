// lib/models/customer_model.dart

import 'address_model.dart';

class CustomerModel {
  final String? id;
  final String name;
  final List<String> phoneNumbers;      // multiple phone numbers
  final String? email;
  final String? gstin;
  final List<AddressModel> addresses;   // multiple addresses (billing + delivery)
  final String? notes;
  final double balance;                 // outstanding balance (+ve = they owe, -ve = we owe)
  final DateTime createdAt;

  CustomerModel({
    this.id,
    required this.name,
    required this.phoneNumbers,
    this.email,
    this.gstin,
    this.addresses = const [],
    this.notes,
    this.balance = 0.0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'name':         name,
    'phoneNumbers': phoneNumbers,
    'email':        email ?? '',
    'gstin':        gstin ?? '',
    'addresses':    addresses.map((a) => a.toMap()).toList(),
    'notes':        notes ?? '',
    'balance':      balance,
    'createdAt':    createdAt.toIso8601String(),
  };

  factory CustomerModel.fromMap(Map<String, dynamic> m, String docId) {
    return CustomerModel(
      id:           docId,
      name:         m['name'] ?? '',
      phoneNumbers: List<String>.from(m['phoneNumbers'] ?? []),
      email:        m['email'],
      gstin:        m['gstin'],
      addresses:    (m['addresses'] as List<dynamic>?)
          ?.map((a) => AddressModel.fromMap(Map<String, dynamic>.from(a)))
          .toList() ?? [],
      notes:        m['notes'],
      balance:      (m['balance'] ?? 0).toDouble(),
      createdAt:    DateTime.parse(
          m['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Get the default billing address
  AddressModel? get defaultBillingAddress {
    try {
      return addresses.firstWhere(
        (a) => a.isDefault && (a.type == 'billing' || a.type == 'both'),
      );
    } catch (_) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }

  /// Get the default shipping address
  AddressModel? get defaultShippingAddress {
    try {
      return addresses.firstWhere(
        (a) => a.isDefault && (a.type == 'shipping' || a.type == 'both'),
      );
    } catch (_) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }

  /// Get primary phone
  String get primaryPhone =>
      phoneNumbers.isNotEmpty ? phoneNumbers.first : '';
}
