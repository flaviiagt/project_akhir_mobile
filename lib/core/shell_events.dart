import 'package:flutter/foundation.dart';

/// Permintaan pindah tab bottom navigation dari widget mana pun
/// (mis. foto profil di app bar -> tab Profil = indeks 4).
/// MainShell mendengarkan nilai ini lalu mengosongkannya lagi.
final ValueNotifier<int?> shellTabRequest = ValueNotifier<int?>(null);
