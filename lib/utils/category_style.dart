import 'package:flutter/material.dart';

/// Ikon + warna pastel tiap kategori pengeluaran.
class CategoryStyle {
  const CategoryStyle(this.icon, this.bg, this.fg);
  final IconData icon;
  final Color bg;
  final Color fg;
}

CategoryStyle categoryStyle(String category) {
  switch (category) {
    case 'Akomodasi':
      return const CategoryStyle(
        Icons.apartment,
        Color(0xFFD6ECFF),
        Color(0xFF1B5A8C),
      );
    case 'Visa & Paspor':
      return const CategoryStyle(
        Icons.badge_outlined,
        Color(0xFFFFE3CF),
        Color(0xFFA5642A),
      );
    case 'Tiket Pesawat':
      return const CategoryStyle(
        Icons.flight,
        Color(0xFFD7F5E6),
        Color(0xFF1E7A52),
      );
    case 'Tes Bahasa':
      return const CategoryStyle(
        Icons.translate,
        Color(0xFFEBDDFB),
        Color(0xFF6B3FA0),
      );
    case 'Makan & Hidup':
      return const CategoryStyle(
        Icons.restaurant,
        Color(0xFFFFF0B8),
        Color(0xFF8A6A00),
      );
    case 'Transportasi':
      return const CategoryStyle(
        Icons.directions_bus,
        Color(0xFFCFF1F1),
        Color(0xFF00696E),
      );
    default:
      return const CategoryStyle(
        Icons.category_outlined,
        Color(0xFFE9E7E2),
        Color(0xFF4C6075),
      );
  }
}
