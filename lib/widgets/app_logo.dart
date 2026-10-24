import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Logo StudyTrip: lingkaran slate-blue dengan ikon pesawat lepas landas.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.slate,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.flight_takeoff, color: Colors.white, size: size * 0.52),
    );
  }
}
