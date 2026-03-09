import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_colors.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as ap;
import 'providers/bookmarks_provider.dart';
import 'providers/listings_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Enable Firestore offline persistence (survives app restarts without network)
    FirebaseFirestore.instance.settings =
        const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
    // Register background FCM handler (must be called after Firebase.initializeApp)
    await NotificationService.registerBackgroundHandler();
  } catch (e) {
    firebaseError = e.toString();
  }
  runApp(KigaliServicesApp(firebaseError: firebaseError));
}

class KigaliServicesApp extends StatelessWidget {
  const KigaliServicesApp({super.key, this.firebaseError});
  final String? firebaseError;

  @override
  Widget build(BuildContext context) {
    if (firebaseError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _FirebaseSetupScreen(error: firebaseError!),
      );
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ap.AuthProvider(AuthService()),
        ),
        ChangeNotifierProvider(
          create: (_) => ListingsProvider(FirestoreService()),
        ),
        ChangeNotifierProvider(
          create: (_) => BookmarksProvider(FirestoreService()),
        ),
      ],
      child: MaterialApp(
        title: 'Kigali City Services',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: kNavy,
          colorScheme: const ColorScheme.dark(
            primary: kGold,
            surface: kNavy,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: kNavyLight,
            foregroundColor: kWhite,
            elevation: 0,
          ),
        ),
        home: const _RootGate(),
      ),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ap.AuthProvider>();

    if (auth.status == ap.AuthStatus.initial ||
        auth.status == ap.AuthStatus.loading) {
      return const Scaffold(
        backgroundColor: kNavy,
        body: Center(
          child: CircularProgressIndicator(color: kGold),
        ),
      );
    }

    if (auth.isAuthenticated) {
      return const MainScreen();
    }

    return const AuthScreen();
  }
}

class _FirebaseSetupScreen extends StatelessWidget {
  const _FirebaseSetupScreen({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cloud_off, color: Color(0xFFF5A623), size: 56),
              const SizedBox(height: 24),
              const Text(
                'Firebase Not Configured',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'To run this app you need to connect it to your Firebase project.\n\n'
                '1. Go to console.firebase.google.com\n'
                '2. Create a project & enable Email/Password Auth\n'
                '3. Create a Firestore database\n'
                '4. Register your Android/iOS app\n'
                '5. In the terminal, run:\n',
                style: TextStyle(color: Color(0xFFB0C4DE), fontSize: 14, height: 1.6),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2C42),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'dart pub global activate flutterfire_cli\nflutterfire configure',
                  style: TextStyle(
                    color: Color(0xFFF5A623),
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Error details:',
                style: TextStyle(color: Color(0xFFB0C4DE), fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                error,
                style: const TextStyle(color: Colors.redAccent, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
