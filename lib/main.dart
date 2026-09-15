import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/settings_provider.dart';
import 'services/hive_service.dart';
import 'screens/login_screen.dart';
import 'screens/inventory_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive Init
  await Hive.initFlutter();
  await Hive.openBox(HiveService.boxPreferences);

  // Firebase Init
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Explicit rather than relying on the platform default (on by default
    // on Android/iOS, off by default on web) — without it, unchanged docs
    // get re-read (and re-billed) from scratch on every app open.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, InventoryProvider>(
          create: (_) => InventoryProvider(),
          update: (_, auth, inventory) {
            inventory!.update(auth.user?.uid);
            return inventory;
          },
        ),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          InventoryProvider,
          CartProvider
        >(
          create: (context) => CartProvider(
            Provider.of<InventoryProvider>(context, listen: false),
          ),
          update: (_, auth, inventory, cart) {
            cart!.updateInventory(inventory);
            cart.updateAuth(auth.user?.uid);
            return cart;
          },
        ),
      ],
      child: MaterialApp(
        title: 'StockSmart',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF1E1E1E), // Slate Grey
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF262626),
            elevation: 8,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            contentTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            actionTextColor: Colors.deepOrange,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.isAuthenticated) {
      return const InventoryScreen(); // To be created
    } else {
      return const LoginScreen(); // To be created
    }
  }
}
