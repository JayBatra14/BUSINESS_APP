// lib/models/address_model.dart

class AddressModel {
  final String id;
  final String label;       // e.g. "Home", "Office", "Warehouse"
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String type;        // 'billing' | 'shipping' | 'both'
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    this.type = 'both',
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() => {
    'id':           id,
    'label':        label,
    'addressLine1': addressLine1,
    'addressLine2': addressLine2 ?? '',
    'city':         city,
    'state':        state,
    'pincode':      pincode,
    'type':         type,
    'isDefault':    isDefault,
  };

  factory AddressModel.fromMap(Map<String, dynamic> m) => AddressModel(
    id:           m['id'] ?? '',
    label:        m['label'] ?? '',
    addressLine1: m['addressLine1'] ?? '',
    addressLine2: m['addressLine2'],
    city:         m['city'] ?? '',
    state:        m['state'] ?? '',
    pincode:      m['pincode'] ?? '',
    type:         m['type'] ?? 'both',
    isDefault:    m['isDefault'] ?? false,
  );

  String get fullAddress {
    final line2 = (addressLine2 ?? '').isNotEmpty ? ', $addressLine2' : '';
    return '$addressLine1$line2, $city, $state - $pincode';
  }

  AddressModel copyWith({
    String? id,
    String? label,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,
    String? type,
    bool? isDefault,
  }) {
    return AddressModel(
      id:           id ?? this.id,
      label:        label ?? this.label,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city:         city ?? this.city,
      state:        state ?? this.state,
      pincode:      pincode ?? this.pincode,
      type:         type ?? this.type,
      isDefault:    isDefault ?? this.isDefault,
    );
  }
}
