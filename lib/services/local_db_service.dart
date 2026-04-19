// lib/services/local_db_service.dart

import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/business_model.dart';

class LocalDbService {
  // Singleton
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  final _uuid = const Uuid();

  // ── Get Hive boxes
  Box get _businessBox => Hive.box('businesses');
  Box get _settingsBox  => Hive.box('settings');

  // ── Save currently active business ID
  Future<void> setActiveBusinessId(String id) async {
    await _settingsBox.put('activeBusinessId', id);
  }

  String? getActiveBusinessId() {
    return _settingsBox.get('activeBusinessId');
  }

  // ── Save logo image to local app storage and return its path
  Future<String?> saveLogoLocally(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logoDir = Directory('${appDir.path}/logos');
      if (!await logoDir.exists()) {
        await logoDir.create(recursive: true);
      }
      final fileName = '${_uuid.v4()}.jpg';
      final savedFile = await imageFile.copy('${logoDir.path}/$fileName');
      return savedFile.path;
    } catch (e) {
      print('Logo save error: $e');
      return null;
    }
  }

  // ── Save business to Hive
  Future<String> saveBusiness({
    required BusinessModel business,
    File? logoFile,
  }) async {
    // Generate unique ID for this business
    final businessId = _uuid.v4();

    // Save logo locally if provided
    String? logoPath;
    if (logoFile != null) {
      logoPath = await saveLogoLocally(logoFile);
    }

    // Build the map to store
    final data = business.toMap();
    data['id']      = businessId;
    data['logoPath'] = logoPath ?? '';

    // Save into Hive box with businessId as the key
    await _businessBox.put(businessId, data);

    // Remember which business is active
    await setActiveBusinessId(businessId);

    return businessId;
  }

  // ── Fetch a business by ID
  BusinessModel? getBusiness(String businessId) {
    final data = _businessBox.get(businessId);
    if (data == null) return null;
    return BusinessModel.fromMap(Map<String, dynamic>.from(data), businessId);
  }

  // ── Fetch ALL businesses (for multi-business support)
  List<BusinessModel> getAllBusinesses() {
    return _businessBox.keys.map((key) {
      final data = _businessBox.get(key);
      return BusinessModel.fromMap(
          Map<String, dynamic>.from(data), key.toString());
    }).toList();
  }

  // ── Update existing business
  Future<void> updateBusiness(BusinessModel business) async {
    if (business.id == null) return;
    final data = business.toMap();
    data['id'] = business.id;
    await _businessBox.put(business.id, data);
  }

  // ── Delete a business
  Future<void> deleteBusiness(String businessId) async {
    await _businessBox.delete(businessId);
  }
}