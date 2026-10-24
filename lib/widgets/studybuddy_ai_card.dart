import 'package:flutter/material.dart';

import '../data/gemini_service.dart';
import '../theme/app_theme.dart';

/// Kartu "StudyBuddy AI: Asisten Visa & Regulasi (Powered by Gemini)"
class StudyBuddyAiCard extends StatelessWidget {
  const StudyBuddyAiCard({super.key});

  void _openAiAssistant(BuildContext context, {String? initialQuery}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StudyBuddyAiModal(initialQuery: initialQuery),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006D77), Color(0xFF135359), Color(0xFF1A464C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006D77).withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STUDYBUDDY AI',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: const Color(0xFF83C5BE)
                                .withValues(alpha: 0.95),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Asisten Visa & Regulasi',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF83C5BE).withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 13,
                          color: Colors.amberAccent,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Gemini AI',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Deskripsi
              Text(
                'Tanya jawab regulasi visa, jam kerja, asuransi, dan tips studi langsung dijawab oleh Google Gemini.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),

              const SizedBox(height: 16),

              // Tombol prompt 1: Batas jam kerja part-time UK
              _promptButton(
                context: context,
                icon: Icons.business_center_outlined,
                label: 'Batas jam kerja part–time UK',
                query: 'Berapa batas jam kerja part-time untuk visa student di UK?',
              ),

              const SizedBox(height: 10),

              // Tombol prompt 2: Aktivasi NHS Student
              _promptButton(
                context: context,
                icon: Icons.medical_services_outlined,
                label: 'Aktivasi NHS Student',
                query: 'Bagaimana cara dan alur aktivasi asuransi NHS untuk mahasiswa baru di UK?',
              ),

              const SizedBox(height: 10),

              // Tombol prompt 3: Tips hemat biaya hidup
              _promptButton(
                context: context,
                icon: Icons.savings_outlined,
                label: 'Tips hemat biaya hidup di UK',
                query: 'Berikan tips praktis menghemat biaya makan, transportasi, dan kebutuhan sehari-hari saat kuliah di UK.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _promptButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String query,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openAiAssistant(context, initialQuery: query),
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal Chat Interaktif StudyBuddy AI dengan Google Gemini
class _StudyBuddyAiModal extends StatefulWidget {
  final String? initialQuery;

  const _StudyBuddyAiModal({this.initialQuery});

  @override
  State<_StudyBuddyAiModal> createState() => _StudyBuddyAiModalState();
}

class _StudyBuddyAiModalState extends State<_StudyBuddyAiModal> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  String _activeApiKey = '';
  bool _isCheckingKey = true;

  @override
  void initState() {
    super.initState();
    _loadKeyStatus();

    _messages.add(
      const _ChatMessage(
        isAi: true,
        text:
            'Halo! Saya StudyBuddy AI yang didukung Google Gemini 🤖✨.\n\n'
            'Siap membantu menjawab pertanyaan seputar regulasi visa student, batasan jam kerja, aktivasi NHS, adaptasi kampus, dan panduan hidup di luar negeri. Ada yang ingin kamu tanyakan?',
      ),
    );

    if (widget.initialQuery != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendUserQuery(widget.initialQuery!);
      });
    }
  }

  Future<void> _loadKeyStatus() async {
    final key = await GeminiService.instance.getActiveApiKey();
    if (mounted) {
      setState(() {
        _activeApiKey = key;
        _isCheckingKey = false;
      });
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
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

    final response = await GeminiService.instance.sendMessage(trimmed);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _messages.add(_ChatMessage(isAi: true, text: response));
      });
      _scrollToBottom();
    }
  }

  void _handleSend() {
    final text = _inputCtrl.text;
    _inputCtrl.clear();
    _sendUserQuery(text);
  }

  void _showApiKeyDialog() async {
    final currentKey = await GeminiService.instance.getActiveApiKey();
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
            Text(
              'Pengaturan API Key Gemini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Google Gemini API Key Anda. Kunci ini akan disimpan di perangkat secara aman.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.slate,
                height: 1.4,
              ),
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
            const SizedBox(height: 10),
            const Text(
              'Tips: Dapatkan API Key gratis di aistudio.google.com tanpa kartu kredit.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.slate,
                fontStyle: FontStyle.italic,
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
              final messenger = ScaffoldMessenger.of(context);
              await GeminiService.instance.saveApiKey(keyCtrl.text);
              if (!mounted) return;
              _loadKeyStatus();
              nav.pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('API Key Gemini berhasil diperbarui!'),
                  backgroundColor: AppColors.teal,
                ),
              );
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
        title: const Text(
          'Hapus Obrolan?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Semua riwayat percakapan dengan StudyBuddy AI akan dibersihkan.',
        ),
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
                _messages.clear();
                _messages.add(
                  const _ChatMessage(
                    isAi: true,
                    text: 'Obrolan telah dibersihkan. Silakan tanyakan hal lain seputar regulasi studi dan visa!',
                  ),
                );
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'StudyBuddy AI',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: AppColors.teal,
                          ),
                        ],
                      ),
                      Text(
                        'Didukung Google Gemini 3.8 Flash',
                        style: TextStyle(fontSize: 11, color: AppColors.slate),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Pengaturan API Key',
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.slate,
                  ),
                  onPressed: _showApiKeyDialog,
                ),
                IconButton(
                  tooltip: 'Bersihkan Obrolan',
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.slate,
                  ),
                  onPressed: _confirmResetChat,
                ),
                IconButton(
                  tooltip: 'Tutup',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Banner pengingat jika API key belum diisi
          if (!_isCheckingKey && _activeApiKey.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECE5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF09873)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Color(0xFFC8451B),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'API Key Gemini belum diatur. Klik tombol untuk mengaturnya.',
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Atur Key',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length && _isLoading) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.teal,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Gemini sedang berpikir...',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.slate,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final m = _messages[i];
                return Align(
                  alignment: m.isAi
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85,
                    ),
                    decoration: BoxDecoration(
                      color: m.isAi ? Colors.white : AppColors.teal,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: m.isAi
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        if (m.isAi)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  size: 13,
                                  color: AppColors.teal,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Gemini',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.teal.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                ),
                              ],
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
              },
            ),
          ),

          // Bottom Input field
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEBE8E3))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Tanyakan regulasi, visa, atau tips studi...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.slate,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF3F5F7),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                  style: IconButton.styleFrom(backgroundColor: AppColors.teal),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                        ),
                  onPressed: _isLoading ? null : _handleSend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool isAi;
  final String text;

  const _ChatMessage({required this.isAi, required this.text});
}
