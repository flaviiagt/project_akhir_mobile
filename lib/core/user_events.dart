import 'package:flutter/foundation.dart';

/// Dinaikkan setiap kali profil (nama/foto) berubah, supaya Beranda
/// memuat ulang nama & foto tanpa restart.
final ValueNotifier<int> profileVersion = ValueNotifier<int>(0);