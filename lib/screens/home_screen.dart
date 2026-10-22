import 'package:flutter/material.dart';
import '../data/app_db.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'checklist_screen.dart';
import 'itinerary_screen.dart';
import 'notes_screen.dart';
import 'quiz_screen.dart';

// TODO(integrasi): ambil nama dari sesi login Member 1.
const kUserName = 'Mahasiswa';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChecklistItem> _items = [];
  int _itinCount = 0, _noteCount = 0;
  String? _best;
  String _destination = '';
  DateTime? _departure;

  @override
  void initState() {
    super.initState();
    AppDb.version.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AppDb.version.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final db = AppDb.instance;
    final items = await db.checklist();
    final itin = await db.query('itinerary');
    final notes = await db.query('notes');
    final scores = await db.query('quiz_scores', orderBy: 'score DESC');
    final dest = await db.getSetting('destination');
    final dep = await db.getSetting('departure');
    if (!mounted) return;
    setState(() {
      _items = items;
      _itinCount = itin.length;
      _noteCount = notes.length;
      _best = scores.isEmpty ? null : '${scores.first['score']}/${scores.first['total']}';
      _destination = dest ?? '';
      _departure = dep == null ? null : DateTime.tryParse(dep);
    });
  }

  Future<void> _editTrip() async {
    final ctrl = TextEditingController(text: _destination);
    DateTime? date = _departure;
    await showFormSheet<void>(context, (c) => StatefulBuilder(builder: (c, setS) {
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Tujuan & Keberangkatan', style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Tujuan studi')),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.event),
              label: Text(date == null ? 'Pilih tanggal keberangkatan' : dateFmt.format(date!)),
              onPressed: () async {
                final p = await showDatePicker(
                  context: c,
                  initialDate: date ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 6)),
                );
                if (p != null) setS(() => date = p);
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (ctrl.text.trim().isEmpty) {
                  showSnack(c, 'Tujuan studi tidak boleh kosong');
                  return;
                }
                await AppDb.instance.setSetting('destination', ctrl.text.trim());
                if (date != null) await AppDb.instance.setSetting('departure', fmtDate(date)!);
                if (c.mounted) Navigator.pop(c);
              },
              child: const Text('Simpan'),
            ),
          ]);
        }));
  }

  void _open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final total = _items.length;
    final done = _items.where((e) => e.done).length;
    final pct = total == 0 ? 0.0 : done / total;
    final upcoming = _items.where((e) => !e.done && e.deadline != null).toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
    final next = upcoming.isEmpty ? null : upcoming.first;
    final daysLeft = _departure == null ? null : daysUntil(_departure!);
    final nextDays = next == null ? null : daysUntil(next.deadline!);

    String countdown;
    if (daysLeft == null) {
      countdown = 'Atur tanggal keberangkatanmu';
    } else if (daysLeft >= 0) {
      countdown = 'Tersisa $daysLeft hari menuju keberangkatan';
    } else {
      countdown = 'Tanggal keberangkatan sudah lewat';
    }

    String deadlineText = '';
    var late = false;
    if (next != null && nextDays != null) {
      late = nextDays < 0;
      deadlineText = late
          ? 'Terlambat ${-nextDays} hari'
          : (nextDays == 0 ? 'Batas waktu hari ini' : 'Batas waktu $nextDays hari lagi');
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
            // Top bar
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: kSecondary, shape: BoxShape.circle),
                child: const Icon(Icons.flight_takeoff, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('STUDYTRIP',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: kAmberDark)),
                Text('Beranda', style: headlineStyle(18, weight: FontWeight.w600)),
              ]),
              const Spacer(),
              IconButton(
                tooltip: 'Pengingat',
                onPressed: () => showSnack(
                    context, next == null ? 'Tidak ada pengingat aktif' : 'Berikutnya: ${next.title} • $deadlineText'),
                icon: const Icon(Icons.notifications_none, color: kSecondary),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ]),
            const SizedBox(height: 16),

            // Badge + sapaan
            Wrap(spacing: 8, runSpacing: 6, children: [
              const Pill('PERJALANAN AKTIF', bg: kAmberTint, fg: kAmberDark),
              if (_destination.isNotEmpty) Pill('🌍 $_destination', bg: kBlueTint, fg: kSecondary),
            ]),
            const SizedBox(height: 10),
            Text('Halo, $kUserName! 👋', style: headlineStyle(30, height: 1.15)),
            const SizedBox(height: 4),
            Text(
              _destination.isEmpty ? 'Wujudkan mimpimu kuliah di luar negeri.' : 'Wujudkan mimpimu kuliah di $_destination.',
              style: const TextStyle(color: kSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 18),

            // Kartu hero
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kNavy, Color(0xFF14526B), kPrimary],
                  ),
                ),
                child: Stack(children: [
                  const Positioned(
                    right: -28,
                    top: -20,
                    child: Icon(Icons.public, size: 170, color: Color(0x1FFFFFFF)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Flexible(
                          child: Pill(
                            _departure == null ? 'Atur tanggal' : dateFmt.format(_departure!),
                            bg: const Color(0xE6FFF7ED),
                            fg: kAmberDark,
                            icon: Icons.calendar_month,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Ubah tujuan',
                          onPressed: _editTrip,
                          style: IconButton.styleFrom(backgroundColor: const Color(0x33FFFFFF)),
                          icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                        ),
                      ]),
                      const SizedBox(height: 36),
                      const Pill('TARGET UTAMA', bg: kTertiary, fg: kOnAmber),
                      const SizedBox(height: 10),
                      Text(
                        _destination.isEmpty ? 'Belum ada tujuan' : _destination,
                        style: headlineStyle(26, color: Colors.white, height: 1.15),
                      ),
                      const SizedBox(height: 6),
                      Text(countdown,
                          style: const TextStyle(color: Color(0xE6FFFFFF), fontWeight: FontWeight.w500)),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: kTertiary, foregroundColor: kOnAmber),
                          onPressed: () => _open(const ChecklistScreen()),
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          iconAlignment: IconAlignment.end,
                          label: const Text('Buka Checklist Persiapan'),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Progres + tenggat terdekat
            SoftCard(
              color: late ? kDangerTint : kTealTint,
              shadow: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () => _open(const ChecklistScreen()),
              child: Row(children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: Stack(alignment: Alignment.center, children: [
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: CircularProgressIndicator(
                        value: pct,
                        strokeWidth: 4,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white,
                        color: late ? kDanger : kPrimary,
                      ),
                    ),
                    Text('${(pct * 100).round()}%',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w800, color: late ? kDanger : kPrimary)),
                  ]),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      next?.title ?? (total == 0 ? 'Belum ada tugas' : 'Semua tugas selesai 🎉'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (next != null)
                      Text(deadlineText,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: late ? kDanger : kSecondary)),
                    Text('$done dari $total tugas selesai', style: const TextStyle(fontSize: 12, color: kSecondary)),
                  ]),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Cek', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),

            // Aksi cepat
            const SectionHeader('Fitur persiapan', 'Aksi Cepat'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _quick(Icons.checklist, 'Checklist', '$done/$total selesai', kTealTint, () => _open(const ChecklistScreen())),
                _quick(Icons.map_outlined, 'Itinerary', '$_itinCount agenda', kBlueTint, () => _open(const ItineraryScreen())),
                _quick(Icons.sticky_note_2_outlined, 'Catatan', '$_noteCount catatan', kAmberTint, () => _open(const NotesScreen())),
                _quick(Icons.quiz_outlined, 'Travel Quiz', _best == null ? 'Belum dimainkan' : 'Terbaik $_best', kTealTint, () => _open(const QuizScreen())),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _quick(IconData icon, String title, String sub, Color tint, VoidCallback onTap) {
    return SoftCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        CircleAvatar(backgroundColor: tint, child: Icon(icon, color: kPrimary)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: headlineStyle(16, weight: FontWeight.w700)),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: kSecondary)),
        ]),
      ]),
    );
  }
}
