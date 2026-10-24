import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/app_theme.dart';
import '../../../core/auth_service.dart';
import '../../../widgets/st_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _hide = true;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.register(
        _name.text.trim(),
        _username.text.trim().toLowerCase(),
        _email.text.trim(),
        _pass.text,
      );
      _snack('Registrasi berhasil, silakan login');
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eye = IconButton(
      icon: Icon(
        _hide ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: () => setState(() => _hide = !_hide),
    );

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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Mulai\nPetualanganmu! 🎓',
                    style: AppText.headline(34, weight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Buat akun StudyTrip dan rencanakan studimu.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 24),
                StCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      StField(
                        label: 'Nama Lengkap',
                        controller: _name,
                        icon: Icons.person_outline,
                        hint: 'Nama lengkapmu',
                        textCapitalization: TextCapitalization.words,
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return 'Nama wajib diisi';
                          if (t.length < 2) return 'Nama minimal 2 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      StField(
                        label: 'Username',
                        controller: _username,
                        icon: Icons.alternate_email,
                        hint: 'huruf kecil, angka, _ atau .',
                        validator: (v) =>
                            AuthService.isValidUsername(v) ? null : 'Username 3-20 karakter: huruf, angka, titik, atau _',
                      ),
                      const SizedBox(height: 16),
                      StField(
                        label: 'Email',
                        controller: _email,
                        icon: Icons.mail_outline,
                        hint: 'nama@email.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => AuthService.isValidEmail(v)
                            ? null
                            : 'Email tidak valid',
                      ),
                      const SizedBox(height: 16),
                      StField(
                        label: 'Kata Sandi',
                        controller: _pass,
                        icon: Icons.lock_outline,
                        hint: 'Minimal 8 karakter',
                        obscure: _hide,
                        suffix: eye,
                        validator: (v) {
                          final t = v ?? '';
                          if (t.length < 8) return 'Minimal 8 karakter';
                          if (!RegExp(r'[A-Za-z]').hasMatch(t) ||
                              !RegExp(r'\d').hasMatch(t)) {
                            return 'Harus mengandung huruf dan angka';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      StField(
                        label: 'Konfirmasi Kata Sandi',
                        controller: _confirm,
                        icon: Icons.lock_outline,
                        hint: 'Ulangi kata sandi',
                        obscure: _hide,
                        validator: (v) =>
                            v != _pass.text ? 'Kata sandi tidak sama' : null,
                      ),
                      const SizedBox(height: 24),
                      StButton(
                        label: 'Daftar Akun Sekarang',
                        loading: _loading,
                        onPressed: _register,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(color: AppColors.muted),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Masuk di sini',
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