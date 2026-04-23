// lib/models/order_model.dart

import 'address_model.dart';

class OrderItemModel {
  final String productId;
  final String productName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double discount;     // % discount on this item
  final double taxPercent;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.unit = 'pcs',
    required this.unitPrice,
    this.discount = 0.0,
    this.taxPercent = 0.0,
  });

  double get subtotal => quantity * unitPrice;
  double get discountAmount => subtotal * (discount / 100);
  double get taxableAmount => subtotal - discountAmount;
  double get taxAmount => taxableAmount * (taxPercent / 100);
  double get total => taxableAmount + taxAmount;

  Map<String, dynamic> toMap() => {
    'productId':   productId,
    'productName': productName,
    'quantity':    quantity,
    'unit':        unit,
    'unitPrice':   unitPrice,
    'discount':    discount,
    'taxPercent':  taxPercent,
  };

  factory OrderItemModel.fromMap(Map<String, dynamic> m) => OrderItemModel(
    productId:   m['productId'] ?? '',
    productName: m['productName'] ?? '',
    quantity:    (m['quantity'] ?? 0).toDouble(),
    unit:        m['unit'] ?? 'pcs',
    unitPrice:   (m['unitPrice'] ?? 0).toDouble(),
    discount:    (m['discount'] ?? 0).toDouble(),
    taxPercent:  (m['taxPercent'] ?? 0).toDouble(),
  );
}

class OrderModel {
  final String? id;
  final String orderNumber;
  final String? customerId;
  final String? customerName;
  final AddressModel? billingAddress;
  final AddressModel? shippingAddress;
  final List<OrderItemModel> items;
  final double subtotal;
  final double totalDiscount;
  final double totalTax;
  final double grandTotal;
  final double amountPaid;
  final String status;       // pending, confirmed, shipped, delivered, cancelled
  final String paymentStatus; // unpaid, partial, paid
  final String? paymentMethod; // cash, upi, card, bank_transfer
  final String? notes;
  final DateTime createdAt;

  OrderModel({
    this.id,
    required this.orderNumber,
    this.customerId,
    this.customerName,
    this.billingAddress,
    this.shippingAddress,
    required this.items,
    required this.subtotal,
    this.totalDiscount = 0.0,
    this.totalTax = 0.0,
    required this.grandTotal,
    this.amountPaid = 0.0,
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    this.paymentMethod,
    this.notes,
    required this.createdAt,
  });

  double get balanceDue => grandTotal - amountPaid;

  Map<String, dynamic> toMap() => {
    'orderNumber':     orderNumber,
    'customerId':      customerId ?? '',
    'customerName':    customerName ?? 'Walk-in',
    'billingAddress':  billingAddress?.toMap(),
    'shippingAddress': shippingAddress?.toMap(),
    'items':           items.map((i) => i.toMap()).toList(),
    'subtotal':        subtotal,
    'totalDiscount':   totalDiscount,
    'totalTax':        totalTax,
    'grandTotal':      grandTotal,
    'amountPaid':      amountPaid,
    'status':          status,
    'paymentStatus':   paymentStatus,
    'paymentMethod':   paymentMethod ?? '',
    'notes':           notes ?? '',
    'createdAt':       createdAt.toIso8601String(),
  };

  factory OrderModel.fromMap(Map<String, dynamic> m, String docId) {
    return OrderModel(
      id:              docId,
      orderNumber:     m['orderNumber'] ?? '',
      customerId:      m['customerId'],
      customerName:    m['customerName'],
      billingAddress:  m['billingAddress'] != null
          ? AddressModel.fromMap(Map<String, dynamic>.from(m['billingAddress']))
          : null,
      shippingAddress: m['shippingAddress'] != null
          ? AddressModel.fromMap(Map<String, dynamic>.from(m['shippingAddress']))
          : null,
      items: (m['items'] as List<dynamic>?)
          ?.map((i) => OrderItemModel.fromMap(Map<String, dynamic>.from(i)))
          .toList() ?? [],
      subtotal:       (m['subtotal'] ?? 0).toDouble(),
      totalDiscount:  (m['totalDiscount'] ?? 0).toDouble(),
      totalTax:       (m['totalTax'] ?? 0).toDouble(),
      grandTotal:     (m['grandTotal'] ?? 0).toDouble(),
      amountPaid:     (m['amountPaid'] ?? 0).toDouble(),
      status:         m['status'] ?? 'pending',
      paymentStatus:  m['paymentStatus'] ?? 'unpaid',
      paymentMethod:  m['paymentMethod'],
      notes:          m['notes'],
      createdAt:      DateTime.parse(
          m['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
