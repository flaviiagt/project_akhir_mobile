import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/gemini_service.dart';
import '../data/translate_service.dart';
import '../theme/app_theme.dart';

// =============================================================================
// StudyBuddy AI sebagai FLOATING WINDOW
//
//  - Bubble kecil melayang di atas semua halaman, bisa digeser (drag) dan
//    otomatis menempel ke tepi kiri/kanan.
//  - Ketuk bubble -> terbuka jendela chat mengambang yang juga bisa digeser
//    lewat header-nya. Tombol "turun" (v) mengecilkannya kembali jadi bubble.
//  - Riwayat chat tetap tersimpan saat jendela diminimalkan.
//
// Pemakaian:  StudyBuddyFloating.show(context);   // sekali saja, mis. di
//             initState ToolsPage / MainShell (dalam addPostFrameCallback).
//             StudyBuddyFloating.hide();          // mis. saat logout.
// =============================================================================

class StudyBuddyFloating {
  StudyBuddyFloating._();

  static OverlayEntry? _entry;
  static final ValueNotifier<bool> expanded = ValueNotifier<bool>(false);

  /// Pasang bubble di overlay paling atas aplikasi. Aman dipanggil berulang.
  static void show(BuildContext context) {
    if (_entry != null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _entry = OverlayEntry(builder: (_) => const _FloatingLayer());
    overlay.insert(_entry!);
  }

  /// Lepas bubble & jendela (riwayat chat di jendela ikut hilang).
  static void hide() {
    _entry?.remove();
    _entry = null;
    expanded.value = false;
  }

  static void open() => expanded.value = true;
  static void minimize() => expanded.value = false;
}

/// Kartu lama di halaman Alat (nama & konstruktor sama seperti sebelumnya).
/// Sekarang ketukannya membuka jendela mengambang, bukan bottom sheet.
class StudyBuddyAiCard extends StatelessWidget {
  const StudyBuddyAiCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3C4D5B),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () {
            StudyBuddyFloating.show(context);
            StudyBuddyFloating.open();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.smart_toy_outlined,
                        color: Color(0xFF7BE5E8), size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Study Buddy • AI Asisten Visa & Regulasi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4DD0E1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Online • Siap membantu',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 20),
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

// ---------------------------------------------------------------------------
// Lapisan overlay: bubble + jendela
// ---------------------------------------------------------------------------

class _FloatingLayer extends StatefulWidget {
  const _FloatingLayer();

  @override
  State<_FloatingLayer> createState() => _FloatingLayerState();
}

class _FloatingLayerState extends State<_FloatingLayer> {
  static const double _bubble = 58;
  static const double _edge = 12;

  Offset? _bubblePos; // pojok kiri-atas bubble
  Offset? _panelPos; // pojok kiri-atas jendela

  @override
  void initState() {
    super.initState();
    StudyBuddyFloating.expanded.addListener(_onChange);
  }

  @override
  void dispose() {
    StudyBuddyFloating.expanded.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final pad = mq.padding;
    final kb = mq.viewInsets.bottom;
    final expanded = StudyBuddyFloating.expanded.value;

    final pw = min(size.width - 24, 380.0);
    final ph = min(size.height * 0.65, 540.0);
    final minTop = pad.top + 8;

    _bubblePos ??= Offset(
      size.width - _bubble - _edge,
      size.height - pad.bottom - 170,
    );
    _panelPos ??= Offset(
      (size.width - pw) / 2,
      size.height - pad.bottom - ph - 90,
    );

    // posisi efektif jendela: naik otomatis bila keyboard muncul
    final maxTop = max(minTop, size.height - kb - ph - 8);
    final panelLeft = _panelPos!.dx.clamp(0.0, max(0.0, size.width - pw)).toDouble();
    final panelTop = _panelPos!.dy.clamp(minTop, maxTop).toDouble();

    final bx = _bubblePos!.dx.clamp(0.0, size.width - _bubble).toDouble();
    final by = _bubblePos!.dy
        .clamp(minTop, size.height - pad.bottom - _bubble - 8)
        .toDouble();

    return Stack(
      children: [
        // Latar blur + redup saat jendela terbuka; ketuk di luar = kecilkan
        if (expanded)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: StudyBuddyFloating.minimize,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),

        // Jendela chat (tetap hidup saat diminimalkan agar riwayat tersimpan)
        Positioned(
          left: panelLeft,
          top: panelTop,
          width: pw,
          height: ph,
          child: Offstage(
            offstage: !expanded,
            child: _ChatWindow(
              onDrag: (d) => setState(() {
                _panelPos = Offset(panelLeft + d.dx, panelTop + d.dy);
              }),
            ),
          ),
        ),

        // Bubble
        if (!expanded)
          Positioned(
            left: bx,
            top: by,
            child: GestureDetector(
              onTap: StudyBuddyFloating.open,
              onPanUpdate: (d) => setState(() {
                _bubblePos = Offset(bx + d.delta.dx, by + d.delta.dy);
              }),
              onPanEnd: (_) => setState(() {
                // tempel ke tepi terdekat
                final toRight = (_bubblePos!.dx + _bubble / 2) > size.width / 2;
                _bubblePos = Offset(
                  toRight ? size.width - _bubble - _edge : _edge,
                  _bubblePos!.dy,
                );
              }),
              child: Container(
                width: _bubble,
                height: _bubble,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 28),
                    Positioned(
                      right: 13,
                      top: 13,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4DD0E1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Isi jendela chat
// ---------------------------------------------------------------------------

class _ChatWindow extends StatefulWidget {
  const _ChatWindow({required this.onDrag});
  final ValueChanged<Offset> onDrag;

  @override
  State<_ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends State<_ChatWindow> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  String _activeApiKey = '';
  bool _isCheckingKey = true;

  static const _welcome = _ChatMessage(
    isAi: true,
    text: 'Halo! Saya StudyBuddy AI 🤖✨.\n\n'
        'Siap membantu seputar regulasi visa student, batas jam kerja, '
        'aktivasi NHS, adaptasi kampus, dan hidup di luar negeri. '
        'Ada yang ingin kamu tanyakan?\n\n'
        '📷 Kamu juga bisa memotret tulisan berbahasa asing (papan, menu, surat) '
        'lewat ikon kamera, nanti kuterjemahkan. Hindari memotret paspor atau data pribadi.',
  );

  @override
  void initState() {
    super.initState();
    _messages.add(_welcome);
    _loadKeyStatus();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKeyStatus() async {
    try {
      final key = await GeminiService.instance.getActiveApiKey();
      if (mounted) {
        setState(() {
          _activeApiKey = key;
          _isCheckingKey = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingKey = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendUserQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(isAi: false, text: trimmed));
      _isLoading = true;
    });
    _scrollToBottom();

    String response;
    try {
      response = await GeminiService.instance.sendMessage(trimmed);
    } catch (_) {
      response =
          'Maaf, StudyBuddy sedang tidak bisa menjawab. Periksa koneksi internet lalu coba lagi.';
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _messages.add(_ChatMessage(isAi: true, text: response));
    });
    _scrollToBottom();
  }

  void _addAi(String text) {
    if (!mounted) return;
    setState(() => _messages.add(_ChatMessage(isAi: true, text: text)));
    _scrollToBottom();
  }

  String _mimeOf(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  /// Ambil foto (kamera/galeri) lalu terjemahkan tulisannya.
  Future<void> _pickAndTranslate(ImageSource source) async {
    if (_isLoading) return;

    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1280,
      );
    } catch (_) {
      _addAi('Tidak bisa membuka kamera/galeri. Periksa izin aplikasi di pengaturan HP.');
      return;
    }
    if (picked == null) return;

    late final Uint8List bytes;
    try {
      bytes = await picked.readAsBytes();
    } catch (_) {
      _addAi('Foto tidak bisa dibaca. Coba pilih foto lain.');
      return;
    }
    if (!mounted) return;
    if (bytes.length > 4 * 1024 * 1024) {
      _addAi('Ukuran foto terlalu besar (maks 4 MB). Coba foto ulang atau pilih foto lain.');
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(
        isAi: false,
        text: 'Terjemahkan tulisan di foto ini',
        image: bytes,
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    final result = await TranslateService.instance
        .translateImage(bytes, mimeType: _mimeOf(picked.name));

    if (!mounted) return;
    setState(() => _isLoading = false);
    _addAi(result);
  }

  void _handleSend() {
    final text = _inputCtrl.text;
    _inputCtrl.clear();
    _sendUserQuery(text);
  }

  Future<void> _showApiKeyDialog() async {
    String currentKey = '';
    try {
      currentKey = await GeminiService.instance.getActiveApiKey();
    } catch (_) {}
    if (!mounted) return;
    final keyCtrl = TextEditingController(text: currentKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.key_rounded, color: AppColors.teal),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'API Key Gemini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Google Gemini API Key. Kunci disimpan di perangkat.',
              style: TextStyle(fontSize: 13, color: AppColors.slate, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                labelText: 'Gemini API Key',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: const Color(0xFFF7F8FA),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: () async {
              final nav = Navigator.of(ctx);
              await GeminiService.instance.saveApiKey(keyCtrl.text);
              _loadKeyStatus();
              nav.pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmResetChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Obrolan?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Riwayat percakapan akan dibersihkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              GeminiService.instance.resetChat();
              setState(() {
                _messages
                  ..clear()
                  ..add(const _ChatMessage(
                    isAi: true,
                    text: 'Obrolan dibersihkan. Silakan tanya hal lain seputar visa dan studi!',
                  ));
              });
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 14,
      shadowColor: Colors.black54,
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ---------- header (area geser jendela) ----------
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (d) => widget.onDrag(d.delta),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 8, 4, 6),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 19),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'StudyBuddy AI',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              'Didukung Google Gemini',
                              style: TextStyle(
                                  fontSize: 10.5, color: AppColors.slate),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Pengaturan API Key',
                        icon: const Icon(Icons.settings_outlined,
                            size: 20, color: AppColors.slate),
                        onPressed: _showApiKeyDialog,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Bersihkan obrolan',
                        icon: const Icon(Icons.refresh_rounded,
                            size: 20, color: AppColors.slate),
                        onPressed: _confirmResetChat,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Kecilkan',
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 26, color: AppColors.ink),
                        onPressed: StudyBuddyFloating.minimize,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (!_isCheckingKey && _activeApiKey.isEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECE5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF09873)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFFC8451B)),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'API Key Gemini belum diatur.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFC8451B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _showApiKeyDialog,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Atur',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // ---------- pesan ----------
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length) return const _TypingBubble();
                return _Bubble(message: _messages[i]);
              },
            ),
          ),

          // ---------- chip pertanyaan cepat ----------
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final t in _kAiTemplates)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: Icon(t.icon, size: 14, color: AppColors.teal),
                      label: Text(
                        t.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      onPressed:
                          _isLoading ? null : () => _sendUserQuery(t.query),
                    ),
                  ),
              ],
            ),
          ),

          // ---------- input ----------
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEBE8E3))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => _pickAndTranslate(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined, size: 18),
                          label: const Text('Ambil gambar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.teal,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => _pickAndTranslate(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('Pilih galeri'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.teal,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputCtrl,
                          enabled: !_isLoading,
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: 'Tanya regulasi, visa, tips studi...',
                            hintStyle: const TextStyle(
                                fontSize: 13, color: AppColors.slate),
                            filled: true,
                            fillColor: const Color(0xFFF3F5F7),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                            backgroundColor: AppColors.teal),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.arrow_upward_rounded,
                                color: Colors.white),
                        onPressed: _isLoading ? null : _handleSend,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final m = message;
    return Align(
      alignment: m.isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: m.isAi ? Colors.white : AppColors.teal,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              m.isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.image != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    m.image!,
                    width: 160,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            SelectableText(
              m.text,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: m.isAi ? AppColors.ink : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Gemini sedang berpikir...',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.slate,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiTemplate {
  final IconData icon;
  final String label;
  final String query;
  const _AiTemplate(
      {required this.icon, required this.label, required this.query});
}

const _kAiTemplates = [
  _AiTemplate(
    icon: Icons.access_time_rounded,
    label: 'Batas jam kerja part-time UK',
    query: 'Berapa batas jam kerja part-time untuk visa student di UK?',
  ),
  _AiTemplate(
    icon: Icons.medical_services_outlined,
    label: 'Aktivasi NHS Student',
    query:
        'Bagaimana cara dan alur aktivasi asuransi NHS untuk mahasiswa baru di UK?',
  ),
  _AiTemplate(
    icon: Icons.savings_outlined,
    label: 'Tips hemat biaya hidup di UK',
    query:
        'Berikan tips praktis menghemat biaya makan, transportasi, dan kebutuhan sehari-hari saat kuliah di UK.',
  ),
];

class _ChatMessage {
  final bool isAi;
  final String text;
  final Uint8List? image;
  const _ChatMessage({required this.isAi, required this.text, this.image});
}