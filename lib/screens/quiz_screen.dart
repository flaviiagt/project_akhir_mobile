import 'package:flutter/material.dart';
import '../data/app_db.dart';
import '../data/quiz_data.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const _perRound = 8;
  late List<QuizQ> _qs;
  int _i = 0, _score = 0;
  int? _picked;
  bool _finished = false;
  String? _best;
  List<QuizQ> _used = [];

  @override
  void initState() {
    super.initState();
    _start();
    _loadBest();
  }

void _start() {
  final unused = kQuiz.where((q) => !_used.contains(q)).toList()..shuffle();
  final seen = kQuiz.where((q) => _used.contains(q)).toList()..shuffle();
  _qs = ([...unused, ...seen].take(_perRound).toList())..shuffle();
  _used = List.of(_qs);
  _i = 0;
  _score = 0;
  _picked = null;
  _finished = false;
}

  Future<void> _loadBest() async {
    final r = await AppDb.instance.query('quiz_scores', orderBy: 'score DESC');
    if (!mounted) return;
    setState(() => _best = r.isEmpty ? null : '${r.first['score']}/${r.first['total']}');
  }

  void _pick(int idx) {
    if (_picked != null) return;
    setState(() {
      _picked = idx;
      if (idx == _qs[_i].answer) _score++;
    });
  }

  Future<void> _next() async {
    if (_i + 1 >= _qs.length) {
      await AppDb.instance.insert('quiz_scores', {
        'score': _score,
        'total': _qs.length,
        'played_at': DateTime.now().toIso8601String(),
      });
      await _loadBest();
      if (mounted) setState(() => _finished = true);
    } else {
      setState(() {
        _i++;
        _picked = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Travel Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _finished ? _result() : _question(),
      ),
    );
  }

    Widget _question() {
    final q = _qs[_i];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Text('Soal ${_i + 1}/${_qs.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
        const Spacer(),
        Text('Skor: $_score'),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
            value: (_i + 1) / _qs.length, minHeight: 8, backgroundColor: kTealTint, color: kPrimary),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SoftCard(
                child: Text(q.question,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
            const SizedBox(height: 12),
            for (var k = 0; k < q.options.length; k++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SoftCard(
                  color: _optionColor(q, k),
                  onTap: () => _pick(k),
                  child: Row(children: [
                    Expanded(child: Text(q.options[k])),
                    if (_picked != null && k == q.answer) const Icon(Icons.check_circle, color: Colors.green),
                    if (_picked == k && k != q.answer) const Icon(Icons.cancel, color: kDanger),
                  ]),
                ),
              ),
            if (_picked != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(q.explanation)),
          ]),
        ),
      ),
      if (_picked != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: FilledButton(onPressed: _next, child: Text(_i + 1 >= _qs.length ? 'Lihat Hasil' : 'Lanjut')),
        ),
    ]);
  }
    Color _optionColor(QuizQ q, int k) {
    if (_picked == null) return Colors.white;
    if (k == q.answer) return const Color(0xFFDDEFD9);
    if (k == _picked) return kDangerTint;
    return Colors.white;
  }

  Widget _result() {
    final pct = (_score / _qs.length * 100).round();
    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.emoji_events, size: 72, color: kTertiary),
          const SizedBox(height: 12),
          Text('$_score / ${_qs.length}',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
          Text('$pct% benar'),
          if (_best != null)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text('Skor terbaik: $_best')),
          const SizedBox(height: 24),
          FilledButton(onPressed: () => setState(_start), child: const Text('Main Lagi')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kembali ke Beranda')),
        ]),
      ),
    );
  }
}