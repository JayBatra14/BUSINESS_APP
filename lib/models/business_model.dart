// lib/models/business_model.dart

class BusinessModel {
  final String?  id;
  final String   businessName;
  final String   ownerName;
  final String   businessType;
  final String   phone;
  final String?  alternatePhone;
  final String?  email;
  final String?  gstNumber;
  final String?  logoUrl;   // Firebase URL (if used later)
  final String?  logoPath;  // Local file path (used now)
  final String   address;
  final String   city;
  final String   state;
  final String   pincode;
  final String?  upiId;
  final DateTime createdAt;

  BusinessModel({
    this.id,
    required this.businessName,
    required this.ownerName,
    required this.businessType,
    required this.phone,
    this.alternatePhone,
    this.email,
    this.gstNumber,
    this.logoUrl,
    this.logoPath,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.upiId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'businessName':   businessName,
      'ownerName':      ownerName,
      'businessType':   businessType,
      'phone':          phone,
      'alternatePhone': alternatePhone ?? '',
      'email':          email ?? '',
      'gstNumber':      gstNumber ?? '',
      'logoUrl':        logoUrl ?? '',
      'logoPath':       logoPath ?? '',
      'address':        address,
      'city':           city,
      'state':          state,
      'pincode':        pincode,
      'upiId':          upiId ?? '',
      'createdAt':      createdAt.toIso8601String(),
    };
  }

  factory BusinessModel.fromMap(Map<String, dynamic> map, String docId) {
    return BusinessModel(
      id:             docId,
      businessName:   map['businessName']   ?? '',
      ownerName:      map['ownerName']      ?? '',
      businessType:   map['businessType']   ?? '',
      phone:          map['phone']          ?? '',
      alternatePhone: map['alternatePhone'],
      email:          map['email'],
      gstNumber:      map['gstNumber'],
      logoUrl:        map['logoUrl'],
      logoPath:       map['logoPath'],
      address:        map['address']        ?? '',
      city:           map['city']           ?? '',
      state:          map['state']          ?? '',
      pincode:        map['pincode']        ?? '',
      upiId:          map['upiId'],
      createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}