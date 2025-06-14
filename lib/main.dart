import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:jwellery_billing/screens/main_screen.dart.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(JewelryInventoryApp());
}

class JewelryInventoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jewelry Inventory Management',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        useMaterial3: true,
        fontFamily: 'Segoe UI',
      ),
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
