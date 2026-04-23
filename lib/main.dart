// lib/main.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'screens/business_setup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/local_db_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive with the app's document directory
  final appDocDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);

  // Open the boxes (like tables) we need
  await Hive.openBox('businesses');
  await Hive.openBox('settings');
  await Hive.openBox('customers');
  await Hive.openBox('products');
  await Hive.openBox('orders');
  await Hive.openBox('expenses');
  await Hive.openBox('ledger');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if a business was already set up
    final db = LocalDbService();
    final activeId = db.getActiveBusinessId();
    final hasBusiness = activeId != null && db.getBusiness(activeId) != null;

    return MaterialApp(
      title: 'Business App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: hasBusiness
          ? DashboardScreen(businessId: activeId)
          : const BusinessSetupScreen(),
    );
  }
}