import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/st_widgets.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});
  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _form = GlobalKey<FormState>();
  final _impression = TextEditingController();
  final _suggestion = TextEditingController();
  int _rating = 5;
  bool _sending = false;
  bool _loading = true;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _impression.dispose();
    _suggestion.dispose();
    super.dispose();
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _load() async {
    try {
      final r = await ApiClient.get('feedback.php', auth: true);
      if (mounted) setState(() => _items = r['data']);
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final r = await ApiClient.post('feedback.php', {
        'impression': _impression.text.trim(),
        'suggestion': _suggestion.text.trim(),
        'rating': _rating,
      }, auth: true);
      _snack(r['message']);
      _impression.clear();
      _suggestion.clear();
      setState(() => _rating = 5);
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StAppBar(title: 'Saran & Kesan'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Text(
              'Mata Kuliah\nPemrograman Aplikasi Mobile',
              style: AppText.headline(24, weight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ceritakan kesan dan saranmu untuk mata kuliah ini.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            StCard(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _form,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _impression,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Kesan',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Kesan wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _suggestion,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Saran',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Saran wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (i) => IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            i < _rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: AppColors.amber,
                            size: 36,
                          ),
                          onPressed: () => setState(() => _rating = i + 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    StButton(
                      label: 'Kirim',
                      loading: _sending,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            const StSectionLabel('Riwayat Saya'),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_items.isEmpty)
              const StCard(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Belum ada isian.',
                  style: TextStyle(color: AppColors.muted),
                ),
              )
            else
              ..._items.map((f) {
                final date = (f['created_at'] as String).length >= 16
                    ? (f['created_at'] as String).substring(0, 16)
                    : f['created_at'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x1FF4A261),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: AppColors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${f['rating']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brown,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('KESAN', style: AppText.label(size: 11)),
                        const SizedBox(height: 2),
                        Text(f['impression']),
                        const SizedBox(height: 10),
                        Text('SARAN', style: AppText.label(size: 11)),
                        const SizedBox(height: 2),
                        Text(f['suggestion']),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
