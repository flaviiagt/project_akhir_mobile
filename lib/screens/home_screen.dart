import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/user_events.dart';
import '../data/app_db.dart';
import '../data/models.dart';
import '../data/universities.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'checklist_screen.dart';
import 'itinerary_screen.dart';
import 'notes_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  /// Dipanggil saat foto profil di header diketuk (pindah ke tab Profil).
  final VoidCallback? onProfileTap;
  const HomeScreen({super.key, this.onProfileTap});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChecklistItem> _items = [];
  int _itinCount = 0, _noteCount = 0;
  String? _best;
  String? _program; // dari Profil (server) = kampus tujuan
  DateTime? _departure;
  String? _userName;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    AppDb.version.addListener(_load);
    profileVersion.addListener(_loadUser);
    _load();
    _loadUser();
  }

  @override
  void dispose() {
    AppDb.version.removeListener(_load);
    profileVersion.removeListener(_loadUser);
    super.dispose();
  }

  Future<void> _load() async {
    final db = AppDb.instance;
    final items = await db.checklist();
    final itin = await db.query('itinerary');
    final notes = await db.query('notes');
    final scores = await db.query('quiz_scores', orderBy: 'score DESC');
    final dep = await db.getSetting('departure');
    if (!mounted) return;
    setState(() {
      _items = items;
      _itinCount = itin.length;
      _noteCount = notes.length;
      _best = scores.isEmpty ? null : '${scores.first['score']}/${scores.first['total']}';
      _departure = dep == null ? null : DateTime.tryParse(dep);
    });
  }

  /// Nama, foto, dan program dari server (me.php). Gagal/offline -> tampilan bawaan.
  Future<void> _loadUser() async {
    try {
      final r = await ApiClient.get('me.php', auth: true, redirect: false);
      final u = r['user'] as Map<String, dynamic>?;
      if (u == null || !mounted) return;
      final photo = ApiClient.fileUrl(u['photo'] as String?);
      setState(() {
        _userName = u['name'] as String?;
        _program = u['program'] as String?;
        _photoUrl = photo == null ? null : '$photo?v=${DateTime.now().millisecondsSinceEpoch}';
      });
    } catch (_) {}
  }

  void _open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Widget _avatarFallback() => Container(
        color: kPrimary,
        child: const Icon(Icons.person, color: Colors.white, size: 20),
      );

  /// Foto/ilustrasi hero mengikuti kampus tujuan.
  Widget _heroBackground(University? uni) {
    Widget art() => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [uni?.c1 ?? kPrimary, uni?.c2 ?? kNavy],
            ),
          ),
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 40, right: 0),
              child: Icon(uni?.icon ?? Icons.public, size: 170, color: const Color(0x1FFFFFFF)),
            ),
          ),
        );
    if (uni?.asset != null) {
      return Image.asset(uni!.asset!,
          fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (_, __, ___) => art());
    }
    if (uni?.image != null) {
      return Image.network(uni!.image!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => art(),
          loadingBuilder: (c, child, p) => p == null ? child : art());
    }
    return art();
  }

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

    final uni = findUniversity(_program);
    // Perjalanan aktif selama tanggal keberangkatan belum terlewati.
    final active = daysLeft == null || daysLeft >= 0;
    final first = (_userName ?? '').trim().split(' ').first;

    String countdown;
    if (daysLeft == null) {
      countdown = 'Atur tanggal keberangkatan di Profil';
    } else if (daysLeft > 0) {
      countdown = 'Tersisa $daysLeft hari menuju keberangkatan';
    } else if (daysLeft == 0) {
      countdown = 'Berangkat hari ini';
    } else {
      countdown = 'Tanggal keberangkatan sudah lewat. Ubah di Profil.';
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
              // Foto profil dari server
              InkWell(
                onTap: widget.onProfileTap,
                customBorder: const CircleBorder(),
                child: ClipOval(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: _photoUrl == null
                        ? _avatarFallback()
                        : Image.network(_photoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarFallback()),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Badge status + sapaan
            Wrap(spacing: 8, runSpacing: 6, children: [
              active
                  ? const Pill('PERJALANAN AKTIF', bg: kAmberTint, fg: kAmberDark)
                  : const Pill('TIDAK AKTIF', bg: Color(0xFFEDEEF0), fg: kSecondary),
              if (uni != null) Pill('🌍 ${uni.name}', bg: kBlueTint, fg: kSecondary),
            ]),
            const SizedBox(height: 10),
            Text('Halo, ${first.isEmpty ? 'Mahasiswa' : first}! 👋', style: headlineStyle(30, height: 1.15)),
            const SizedBox(height: 4),
            Text(
              uni == null ? 'Pilih program StudyTrip di tab Profil.' : 'Wujudkan mimpimu kuliah di ${uni.name}.',
              style: const TextStyle(color: kSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 18),

            // Kartu hero (foto berganti sesuai kampus tujuan)
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    child: KeyedSubtree(
                      key: ValueKey(uni?.name ?? 'none'),
                      child: _heroBackground(uni),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.5, 1.0],
                        colors: [Color(0x1A000000), Color(0x80101E2C), Color(0xF20F2537)],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(
                        child: Pill(
                          _departure == null ? 'Belum ada tanggal' : dateFmt.format(_departure!),
                          bg: const Color(0xE6FFF7ED),
                          fg: kAmberDark,
                          icon: Icons.calendar_month,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 64),
                    const Pill('TARGET UTAMA', bg: kTertiary, fg: kOnAmber),
                    const SizedBox(height: 10),
                    Text(
                      uni?.name ?? 'Belum ada tujuan',
                      style: headlineStyle(26, color: Colors.white, height: 1.15),
                    ),
                    const SizedBox(height: 6),
                    if (uni != null)
                      Text(uni.place, style: const TextStyle(color: Color(0xE6FFFFFF), fontWeight: FontWeight.w500))
                    else
                      const Text('Pilih program di tab Profil',
                          style: TextStyle(color: Color(0xE6FFFFFF), fontWeight: FontWeight.w500)),
                    Text(countdown, style: const TextStyle(color: Color(0xCCFFFFFF), fontWeight: FontWeight.w500)),
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