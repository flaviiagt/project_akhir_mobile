import 'package:flutter/material.dart';

import 'st_widgets.dart';

/// App bar halaman Anggaran/Alat/Eksplorasi. Memakai StAppBar milik aplikasi
/// supaya tampilannya seragam (logo, judul, lonceng notifikasi). [actions]
/// adalah aksi tambahan khusus halaman (mis. tombol ubah).
class StudyTripAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StudyTripAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) =>
      StAppBar(title: title, extraActions: actions ?? const []);
}
