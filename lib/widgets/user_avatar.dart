import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/profile_store.dart';
import '../core/shell_events.dart';

/// Foto profil bulat untuk app bar. Mengikuti foto di halaman Profil dan
/// membuka tab Profil saat diketuk. Tanpa foto: huruf pertama nama.
class UserAvatar extends StatefulWidget {
  final double size;
  const UserAvatar({super.key, this.size = 32});

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  @override
  void initState() {
    super.initState();
    ProfileStore.load();
  }

  Widget _fallback(String name) {
    final initial = name.isEmpty ? '' : String.fromCharCode(name.runes.first).toUpperCase();
    return Container(
      color: AppColors.teal,
      alignment: Alignment.center,
      child: initial.isEmpty
          ? Icon(Icons.person, color: Colors.white, size: widget.size * 0.56)
          : Text(initial,
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: widget.size * 0.45)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: ProfileStore.user,
      builder: (context, user, child) {
        final url = ProfileStore.photoUrl;
        final name = ProfileStore.name;
        return Semantics(
          button: true,
          label: 'Buka profil',
          child: InkWell(
            onTap: () => shellTabRequest.value = 4,
            customBorder: const CircleBorder(),
            child: ClipOval(
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: url == null
                    ? _fallback(name)
                    : Image.network(
                        url,
                        key: ValueKey(url),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => _fallback(name),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
