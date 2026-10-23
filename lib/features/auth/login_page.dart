import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/app_theme.dart';
import '../../../core/auth_service.dart';
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

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await AuthService.login(_id.text.trim(), _pass.text);
      await NotificationService.instance.welcome(name: user['name'] as String?);
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
        await NotificationService.instance.welcome(name: u['name'] as String?);
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
                const StAuthHeader(),
                const SizedBox(height: 28),
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
