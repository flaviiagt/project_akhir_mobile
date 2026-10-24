import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/app_theme.dart';
import '../../../core/auth_service.dart';
import '../../../core/current_user.dart';
import '../../../core/idle_guard.dart';
import '../../../services/notification_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    await Future.delayed(const Duration(milliseconds: 900));
    String route = '/login';
    var token = await ApiClient.token;
    if (token != null && await IdleSessionGuard.isExpired()) {
      await AuthService.logout(); // app sempat ditutup lebih dari batas idle
      token = null;
    }
    if (token != null) {
      try {
        await AuthService.me(redirect: false);
        route = '/home';
      } on ApiException catch (e) {
        if (e.statusCode == 401) {
          // token kedaluwarsa / tidak valid
          await ApiClient.clearToken();
          await CurrentUser.clear();
        } else {
          // offline (0) atau server bermasalah (5xx): tetap masuk,
          // data lokal tetap bisa dipakai
          route = '/home';
        }
      }
      if (route == '/home') {
        await NotificationService.instance.rescheduleAll();
      }
    }
    if (mounted) Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flight_takeoff,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'StudyTrip',
              style: AppText.headline(
                36,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Rencanakan studi di luar negerimu',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
