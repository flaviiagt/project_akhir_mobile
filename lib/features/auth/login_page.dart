import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api_client.dart';
import '../../../core/app_theme.dart';
import '../../../core/auth_service.dart';
import '../../../core/current_user.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/st_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _hide = true;
  bool _bioReady = false;
  String _bioLabel = 'Biometrik';

  @override
  void initState() {
    super.initState();
    _initBio();
  }

  @override
  void dispose() {
    _id.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _initBio() async {
    final ready =
        await AuthService.isBiometricEnabled() &&
        await AuthService.biometricAvailable();
    final label = await AuthService.biometricLabel();
    if (mounted) {
      setState(() {
        _bioReady = ready;
        _bioLabel = label;
      });
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  // Tanya izin notifikasi per akun: Izinkan / Tolak disimpan di HP ini,
  // "Nanti" ditanya lagi saat login berikutnya.
  Future<void> _welcomeWithConsent(String? name) async {
    if (!mounted) return;
    final uid = CurrentUser.id;
    final prefs = await SharedPreferences.getInstance();
    final key = 'notif_choice_$uid';
    final saved = uid == null ? null : prefs.getString(key);

    if (saved == 'deny') {
      // akun ini sudah menolak: pengingat tetap mati, tidak ditanya lagi
      await NotificationService.instance.setReminders(false);
      return;
    }
    if (saved == 'allow') {
      await NotificationService.instance.setReminders(true);
      await NotificationService.instance.welcome(name: name);
      return;
    }

    if (!mounted) return;
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0x1F1E8289),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Izinkan notifikasi?',
              textAlign: TextAlign.center,
              style: AppText.headline(22, weight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'StudyTrip ingin mengirim pengingat tenggat dokumen dan jadwal perjalananmu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, 'allow'),
                    child: const Text('Izinkan'),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, 'later'),
                    child: const Text('Nanti'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, 'deny'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.muted,
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (choice == 'allow') {
      // Minta izin sistem + nyalakan pengingat; simpan hanya kalau benar-benar aktif.
      final st = await NotificationService.instance.setReminders(true);
      if (st == NotifStatus.on) {
        if (uid != null) await prefs.setString(key, 'allow');
        await NotificationService.instance.welcome(name: name);
      }
    } else if (choice == 'deny') {
      if (uid != null) await prefs.setString(key, 'deny');
      await NotificationService.instance.setReminders(false);
    }
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await AuthService.login(_id.text.trim(), _pass.text);
      await NotificationService.instance.rescheduleAll();
      await _welcomeWithConsent(user['name'] as String?);
      if (user['offline'] == true) {
        _snack('Masuk mode offline. Data akan disinkronkan saat online.');
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginBio() async {
    setState(() => _loading = true);
    try {
      final u = await AuthService.loginWithBiometric();
      if (u != null && mounted) {
        await NotificationService.instance.rescheduleAll();
        await _welcomeWithConsent(u['name'] as String?);
        if (u['offline'] == true) {
          _snack('Masuk mode offline. Data akan disinkronkan saat online.');
        }
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        _snack('Verifikasi gagal, gunakan kata sandi');
      }
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: StLogo(size: 56),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Selamat Datang\nKembali! 👋',
                    style: AppText.headline(34, weight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Masuk untuk melanjutkan persiapan studimu.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 24),
                StCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      StField(
                        label: 'Email atau Username',
                        controller: _id,
                        icon: Icons.person_outline,
                        hint: 'email atau username',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || v.trim().length < 3)
                            ? 'Isi email atau username'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      StField(
                        label: 'Kata Sandi',
                        controller: _pass,
                        icon: Icons.lock_outline,
                        hint: '••••••••',
                        obscure: _hide,
                        suffix: IconButton(
                          icon: Icon(
                            _hide
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Kata sandi wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      StButton(
                        label: 'Masuk ke Akun',
                        loading: _loading,
                        onPressed: _login,
                      ),
                      if (_bioReady) ...[
                        const SizedBox(height: 12),
                        StButton(
                          label: 'Masuk dengan $_bioLabel',
                          icon: Icons.fingerprint,
                          outlined: true,
                          onPressed: _loginBio,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(color: AppColors.muted),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/register'),
                        child: const Text(
                          'Daftar Sekarang',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
