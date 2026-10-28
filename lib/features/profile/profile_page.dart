import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/user_events.dart';
import '../../../data/app_db.dart';
import '../../../data/models.dart' show fmtDate;
import '../../../data/universities.dart';
import '../../../widgets/common.dart' show dateFmt;
import '../../../widgets/university_picker.dart';
import '../../../core/api_client.dart';
import '../../../core/app_theme.dart';
import '../../../core/auth_service.dart';
import '../../../widgets/st_widgets.dart';
import '../auth/logout.dart';
import '../feedback/feedback_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _bioEnabled = false;
  bool _bioAvailable = false;
  int _photoVersion = DateTime.now().millisecondsSinceEpoch;
  DateTime? _departure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _load() async {
    try {
      final u = await AuthService.me();
      final en = await AuthService.isBiometricEnabled();
      final av = await AuthService.biometricAvailable();
      final dep = await AppDb.instance.getSetting('departure');
      if (!mounted) return;
      setState(() {
        _user = u;
        _bioEnabled = en;
        _bioAvailable = av;
        _departure = dep == null ? null : DateTime.tryParse(dep);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loading = false);
      _snack(e.message);
    }
  }

  // ---------- Foto ----------
  Future<void> _pickPhoto() async {
    ImageSource? source = ImageSource.gallery;
    if (!kIsWeb) {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Ambil dari kamera'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Pilih dari galeri'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      _snack('Ukuran foto maksimal 2 MB');
      return;
    }
    var filename = picked.name;
    if (!filename.contains('.')) filename = '$filename.jpg';

    try {
      await ApiClient.uploadBytes('upload_photo.php', 'photo', bytes, filename);
      _photoVersion = DateTime.now().millisecondsSinceEpoch;
      profileVersion.value++;
      _snack('Foto profil diperbarui');
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  // ---------- Edit profil ----------
  Future<void> _edit() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: _user!['name']);
    University? uni = findUniversity(_user!['program'] as String?);
    DateTime? date = _departure;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit Profil', style: AppText.headline(22)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Nama',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'Nama wajib diisi';
                      if (t.length < 2) return 'Nama minimal 2 karakter';
                      if (t.length > 50) return 'Nama maksimal 50 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  // Program StudyTrip = kampus tujuan (ikut tampil di Beranda)
                  InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () async {
                      final p = await pickUniversity(ctx, selected: uni?.name);
                      if (p != null) setS(() => uni = p);
                    },
                    child: InputDecorator(
                      isEmpty: false,
                      decoration: const InputDecoration(
                        labelText: 'Program StudyTrip (kampus tujuan)',
                        prefixIcon: Icon(Icons.school_outlined),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      child: Text(
                        uni?.name ?? 'Pilih kampus tujuan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: uni == null ? AppColors.muted : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () async {
                      final p = await showDatePicker(
                        context: ctx,
                        initialDate: date ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 6),
                        ),
                      );
                      if (p != null) setS(() => date = p);
                    },
                    child: InputDecorator(
                      isEmpty: false,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal keberangkatan',
                        prefixIcon: Icon(Icons.event),
                      ),
                      child: Text(
                        date == null ? 'Pilih tanggal' : dateFmt.format(date!),
                        style: TextStyle(
                          color: date == null ? AppColors.muted : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  StButton(
                    label: 'Simpan',
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx, true);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.post('profile_update.php', {
        'name': name.text.trim(),
        'program': uni?.name ?? '',
      }, auth: true);
      if (date != null) {
        await AppDb.instance.setSetting('departure', fmtDate(date)!);
      }
      profileVersion.value++;
      _snack('Profil disimpan');
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  // ---------- Biometrik ----------
  Future<String?> _askPassword() {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konfirmasi password', style: AppText.headline(20)),
        content: TextField(
          controller: c,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(ctx, c.text),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBio(bool value) async {
    if (!value) {
      await AuthService.disableBiometric();
      setState(() => _bioEnabled = false);
      return;
    }
    final pass = await _askPassword();
    if (pass == null || pass.isEmpty) return;
    try {
      await AuthService.login(_user!['email'], pass); // verifikasi password
      final ok = await AuthService.enableBiometric(_user!['email'], pass);
      if (ok) {
        setState(() => _bioEnabled = true);
        _snack('Login biometrik diaktifkan');
      } else {
        _snack('Verifikasi biometrik gagal');
      }
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StAppBar(title: 'Profil'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Gagal memuat profil'),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(140, 44),
                    ),
                    onPressed: () {
                      setState(() => _loading = true);
                      _load();
                    },
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(onRefresh: _load, child: _content()),
    );
  }

  Widget _content() {
    final photoPath = ApiClient.fileUrl(_user!['photo']);
    final photo = photoPath == null ? null : '$photoPath?v=$_photoVersion';
    final program = _user!['program'] as String?;
    final uni = findUniversity(program);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        // 1. Identitas
        Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 104,
                  height: 104,
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.container,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: photo != null
                        ? Image.network(
                            photo,
                            headers: ApiClient.imageHeaders,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const StDefaultAvatar(size: 96),
                          )
                        : const StDefaultAvatar(size: 96),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo_camera,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _user!['name'],
              textAlign: TextAlign.center,
              style: AppText.headline(26, weight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              _user!['email'],
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Material(
              color: AppColors.container,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: _edit,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 17,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Edit Profil',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 2. Program StudyTrip (sumber tujuan & tanggal untuk Beranda)
        StCard(
          padding: const EdgeInsets.all(20),
          child: InkWell(
            onTap: _edit,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F7F2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.flight_takeoff,
                    color: Color(0xFF00796B),
                    size: 21,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROGRAM STUDYTRIP',
                        style: AppText.label(color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        uni?.name ??
                            ((program == null || program.isEmpty)
                                ? 'Belum diisi, ketuk untuk memilih kampus'
                                : program),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (uni != null)
                        Text(
                          uni.place,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      if (_departure != null)
                        Text(
                          'Berangkat ${dateFmt.format(_departure!)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF9AA9B7)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 3. Saran & Kesan (FR-29)
        const StSectionLabel('Aktivitas Akademik'),
        StCard(
          child: _PrefRow(
            iconBg: const Color(0xFFE1F0FE),
            iconColor: const Color(0xFF1976D2),
            icon: Icons.school_outlined,
            title: 'Saran & Kesan Kuliah PAM',
            subtitle: 'Pemrograman Aplikasi Mobile',
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF9AA9B7)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeedbackPage()),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 4. Keamanan (FR-05)
        const StSectionLabel('Keamanan'),
        StCard(
          child: _PrefRow(
            iconBg: const Color(0xFFE0F2FE),
            iconColor: const Color(0xFF0284C7),
            icon: Icons.fingerprint,
            title: 'Login Biometrik / Face ID',
            subtitle: _bioAvailable
                ? 'Akses cepat dan aman'
                : (kIsWeb
                      ? 'Tidak tersedia di browser'
                      : 'Tidak tersedia di perangkat ini'),
            trailing: Switch(
              value: _bioEnabled,
              onChanged: _bioAvailable ? _toggleBio : null,
            ),
          ),
        ),
        const SizedBox(height: 28),

        // 5. Logout (FR-07)
        Center(
          child: Material(
            color: const Color(0xFFFEF2F2),
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => confirmLogout(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, size: 18, color: Color(0xFF9A4B3D)),
                    SizedBox(width: 8),
                    Text(
                      'Keluar dari Akun',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9A4B3D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'StudyTrip v1.0.0',
            style: TextStyle(fontSize: 12, color: Color(0xFF8E9CA8)),
          ),
        ),
      ],
    );
  }
}

class _PrefRow extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _PrefRow({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}
