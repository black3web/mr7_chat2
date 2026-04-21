import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'l10n/app_localizations.dart';
import 'services/auth_service.dart';

bool _firebaseOk = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Flutter error handler — prevents app crash, logs instead
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('[Flutter Error] ${details.exceptionAsString()}');
    // Don't rethrow — let app continue
  };

  // Firebase initialization with proper timeout handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 20));
    _firebaseOk = true;
    // Initialize dev account in background (non-blocking)
    AuthService().initDevAccount().catchError(
      (e) => debugPrint('[DevAccount] $e'),
    );
  } catch (e) {
    debugPrint('[Firebase Init Error] $e');
    _firebaseOk = false;
  }

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A0A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize provider — works even if Firebase is unavailable
  final provider = AppProvider();
  if (_firebaseOk) {
    try {
      await provider.init().timeout(const Duration(seconds: 12));
    } catch (e) {
      debugPrint('[Provider Init] $e');
    }
  }

  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: MR7App(firebaseOk: _firebaseOk),
    ),
  );
}

class MR7App extends StatelessWidget {
  final bool firebaseOk;
  const MR7App({super.key, required this.firebaseOk});

  @override
  Widget build(BuildContext context) {
    if (!firebaseOk) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: _FirebaseErrorScreen(),
      );
    }

    final p = context.watch<AppProvider>();
    return MaterialApp(
      title: 'MR7 Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: p.themeMode,
      locale: p.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.generateRoute,
      builder: (context, child) => MediaQuery(
        // Respect system text scale but cap it for UI safety
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            MediaQuery.of(context).textScaler.scale(1.0).clamp(0.85, 1.15),
          ),
        ),
        child: Directionality(
          textDirection: p.language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        ),
      ),
    );
  }
}

class _FirebaseErrorScreen extends StatefulWidget {
  @override
  State<_FirebaseErrorScreen> createState() => _FirebaseErrorScreenState();
}

class _FirebaseErrorScreenState extends State<_FirebaseErrorScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await Future.delayed(const Duration(milliseconds: 800));
    // Restart the app initialization
    main();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0A0A0A),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A0008),
                border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.4)),
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 36, color: Color(0xFFFF1744)),
            ),
            const SizedBox(height: 24),
            const Text(
              'تعذر الاتصال بالخادم',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              'تأكد من اتصالك بالإنترنت\nثم اضغط إعادة المحاولة',
              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _retrying ? null : _retry,
                icon: _retrying
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.refresh_rounded),
                label: Text(_retrying ? 'جاري الاتصال...' : 'إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF1744),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
