import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  static const List<String> _boxes = [
    'businesses',
    'settings',
    'customers',
    'products',
    'orders',
    'expenses',
    'ledger'
  ];

  static Future<void> exportData(BuildContext context) async {
    try {
      final Map<String, dynamic> backupData = {};
      
      for (final boxName in _boxes) {
        final box = Hive.box(boxName);
        final Map<String, dynamic> boxData = {};
        for (final key in box.keys) {
          boxData[key.toString()] = box.get(key);
        }
        backupData[boxName] = boxData;
      }

      final jsonString = jsonEncode(backupData);
      
      final directory = await getTemporaryDirectory();
      final dateStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final file = File('${directory.path}/business_app_backup_$dateStr.json');
      await file.writeAsString(jsonString);

      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Business App Backup');
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  static Future<void> importData(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final Map<String, dynamic> backupData = jsonDecode(jsonString);

        if (!backupData.containsKey('businesses')) {
           throw Exception("Invalid backup file format");
        }

        // Restore
        for (final boxName in _boxes) {
          if (backupData.containsKey(boxName)) {
            final box = Hive.box(boxName);
            await box.clear();
            final Map<String, dynamic> boxData = backupData[boxName] as Map<String, dynamic>;
            for (final key in boxData.keys) {
              await box.put(key, boxData[key]);
            }
          }
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Data restored successfully! Please close and reopen the app.'), 
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
