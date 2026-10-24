import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'core/current_user.dart';
import 'core/idle_guard.dart';
import 'data/app_db.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/auth/splash_page.dart';
import 'features/shell/main_shell.dart';
import 'services/notification_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Anggota 2: database lokal + format tanggal + notifikasi deadline.
  String? startupError;
  try {
    if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
    await initializeDateFormatting('id_ID');
    await CurrentUser.restore(); // siapa pemilik data lokal (juga saat offline)
    await AppDb.instance.db;
  } catch (e, st) {
    startupError = '$e\n\n$st';
  }
  // Cloud (Supabase). Jika belum diisi/gagal, aplikasi tetap jalan offline.
  try {
    if (SupabaseConfig.isSet) {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
    }
  } catch (_) {}
  try {
    await NotificationService.instance.init();
    await NotificationService.instance.rescheduleAll();
  } catch (_) {
    // notifikasi tidak boleh menghentikan aplikasi
  }

  runApp(
    startupError == null
        ? const StudyTripApp()
        : MaterialApp(
            home: Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText('Gagal memulai:\n$startupError'),
                ),
              ),
            ),
          ),
  );
}

class StudyTripApp extends StatelessWidget {
  const StudyTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyTrip',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) =>
          IdleSessionGuard(child: child ?? const SizedBox.shrink()),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const MainShell(),
      },
    );
  }
}
