import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_logo.dart';

/// Top app bar: logo + "STUDYTRIP" + judul layar.
class StudyTripAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StudyTripAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 68,
      titleSpacing: 16,
      title: Row(
        children: [
          const AppLogo(),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'STUDYTRIP',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brown,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: actions,
    );
  }
}
