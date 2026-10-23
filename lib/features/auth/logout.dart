import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/auth_service.dart';
import '../../../services/notification_service.dart';

Future<void> confirmLogout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        'Keluar dari akun?',
        style: AppText.headline(20, weight: FontWeight.w700),
      ),
      content: const Text('Kamu perlu login lagi untuk masuk ke StudyTrip.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            minimumSize: const Size(100, 44),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Keluar'),
        ),
      ],
    ),
  );
  if (ok == true) {
    await NotificationService.instance
        .cancelAll(); // batalkan pengingat akun ini
    await AuthService.logout();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    }
  }
}
