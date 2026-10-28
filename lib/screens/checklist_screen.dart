import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_db.dart';
import '../data/models.dart';
import '../services/chain_service.dart';
import '../services/checklist_document_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'progress_proof_screen.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});
  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  List<ChecklistItem> _items = [];
  Map<String, List<ChecklistDocument>> _documents = {};
  List<ChainRecord> _seals = [];
  bool _loading = true;
  bool _documentBusy = false;
  final _documentService = ChecklistDocumentService.instance;
  final _chainService = ChainService.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AppDb.instance.checklist();
    final documents = <String, List<ChecklistDocument>>{};
    try {
      for (final item in items) {
        if (item.rid != null) {
          documents[item.rid!] = await _documentService.listForChecklist(
            item.rid!,
          );
        }
      }
    } on ChecklistDocumentException catch (e) {
      if (!mounted) return;
      setState(() {
        _items = items;
        _documents = documents;
        _loading = false;
      });
      showSnack(context, e.message);
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = items;
        _documents = documents;
        _loading = false;
      });
      showSnack(context, 'Dokumen checklist gagal dimuat: $e');
      return;
    }
    final seals = (await _chainService.records())
        .where((record) => record.kind == 'document')
        .toList();
    if (!mounted) return;
    setState(() {
      _items = items;
      _documents = documents;
      _seals = seals;
      _loading = false;
    });
  }

  ChainRecord? _sealFor(ChecklistDocument document) {
    for (final record in _seals) {
      try {
        final payload = ChecklistDocumentService.payloadForSeal(record.payload);
        if (payload?['documentHash'] == document.fileHash) return record;
      } on FormatException {
        continue;
      }
    }
    return null;
  }

  Future<void> _manageDocuments(ChecklistItem item) async {
    if (item.rid == null) {
      showSnack(
        context,
        'Checklist ini belum tersinkron. Coba lagi setelah koneksi tersedia.',
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final documents = _documents[item.rid] ?? const <ChecklistDocument>[];
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * .78,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Dokumen checklist',
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: documents.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text('Belum ada dokumen untuk tugas ini.'),
                            )
                          : ListView(
                              shrinkWrap: true,
                              children: [
                                for (final document in documents)
                                  _documentTile(
                                    document,
                                    sheetContext,
                                    setSheetState,
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _documentBusy
                          ? null
                          : () => _uploadDocument(
                              item,
                              sheetContext,
                              setSheetState,
                            ),
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Tambah dokumen'),
                    ),
                    if (_documentBusy) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                    const SizedBox(height: 4),
                    const Text(
                      'PDF, JPG, PNG, atau WEBP • maksimal 10 MB. File privat dan tidak diunggah ke blockchain.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _documentTile(
    ChecklistDocument document,
    BuildContext sheetContext,
    StateSetter setSheetState,
  ) {
    final seal = _sealFor(document);
    final status = seal == null
        ? 'Belum disegel'
        : switch (seal.status) {
            'confirmed' => 'Tersegel',
            'pending' => 'Menunggu konfirmasi',
            'failed' => 'Penyegelan gagal',
            _ => 'Bukti disiapkan',
          };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.description_outlined),
      title: Text(
        document.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('${_formatBytes(document.fileSize)} • $status'),
      trailing: PopupMenuButton<String>(
        enabled: !_documentBusy,
        onSelected: (action) async {
          switch (action) {
            case 'open':
              await _openDocument(document);
              break;
            case 'seal':
              await _sealDocument(document);
              if (sheetContext.mounted) setSheetState(() {});
              break;
            case 'verify':
              await _verifyDocument(document, seal);
              break;
            case 'retry':
              await _retryDocumentSeal(seal!);
              if (sheetContext.mounted) setSheetState(() {});
              break;
            case 'delete':
              await _deleteDocument(document);
              if (sheetContext.mounted) setSheetState(() {});
              break;
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'open', child: Text('Buka dokumen')),
          if (seal == null)
            const PopupMenuItem(
              value: 'seal',
              child: Text('Segel hash di blockchain'),
            )
          else ...[
            if (seal.status == 'draft' || seal.status == 'failed')
              const PopupMenuItem(
                value: 'retry',
                child: Text('Coba segel lagi'),
              ),
            if (seal.txHash != null)
              const PopupMenuItem(
                value: 'verify',
                child: Text('Verifikasi dokumen'),
              ),
          ],
          const PopupMenuItem(value: 'delete', child: Text('Hapus dokumen')),
        ],
      ),
    );
  }

  Future<void> _uploadDocument(
    ChecklistItem item,
    BuildContext sheetContext,
    StateSetter setSheetState,
  ) async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
    } catch (e) {
      if (mounted) showSnack(context, 'Pemilih file gagal dibuka: $e');
      return;
    }
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) {
        showSnack(context, 'File tidak dapat dibaca. Coba pilih file lain.');
      }
      return;
    }
    setState(() => _documentBusy = true);
    if (sheetContext.mounted) setSheetState(() {});
    try {
      await _documentService.upload(
        checklistRid: item.rid!,
        fileName: file.name,
        bytes: bytes,
      );
      await _load();
      if (mounted) showSnack(context, 'Dokumen diunggah dengan aman.');
    } on ChecklistDocumentException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (e) {
      if (mounted) showSnack(context, 'Upload dokumen gagal: $e');
    } finally {
      if (mounted) setState(() => _documentBusy = false);
      if (sheetContext.mounted) setSheetState(() {});
    }
  }

  Future<void> _openDocument(ChecklistDocument document) async {
    try {
      final url = await _documentService.signedUrl(document);
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        throw const ChecklistDocumentException(
          'Tautan dokumen tidak dapat dibuka di perangkat ini.',
        );
      }
    } on ChecklistDocumentException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (e) {
      if (mounted) showSnack(context, 'Dokumen gagal dibuka: $e');
    }
  }

  Future<void> _sealDocument(ChecklistDocument document) async {
    setState(() => _documentBusy = true);
    try {
      await _chainService.recordDocument(fileHash: document.fileHash);
      await _load();
      if (mounted) {
        showSnack(context, 'Hash dokumen disegel. File-nya tetap privat.');
      }
    } on ChainException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (e) {
      if (mounted) showSnack(context, 'Penyegelan dokumen gagal: $e');
    } finally {
      if (mounted) setState(() => _documentBusy = false);
    }
  }

  Future<void> _retryDocumentSeal(ChainRecord record) async {
    setState(() => _documentBusy = true);
    try {
      await _chainService.retry(record);
      await _load();
      if (mounted) showSnack(context, 'Permintaan penyegelan dikirim ulang.');
    } on ChainException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (e) {
      if (mounted) showSnack(context, 'Penyegelan dokumen gagal: $e');
    } finally {
      if (mounted) setState(() => _documentBusy = false);
    }
  }

  Future<void> _verifyDocument(
    ChecklistDocument document,
    ChainRecord? seal,
  ) async {
    if (seal == null) {
      showSnack(context, 'Belum ada bukti blockchain untuk dokumen ini.');
      return;
    }
    showSnack(context, 'Memeriksa dokumen dan bukti blockchain…');
    try {
      final bytes = await _documentService.download(document);
      final sameFile =
          ChecklistDocumentService.hashBytes(bytes) == document.fileHash;
      final verification = await _chainService.verify(seal);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            sameFile && verification.ok
                ? 'Dokumen terverifikasi'
                : 'Verifikasi belum berhasil',
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sameFile
                      ? 'File sama dengan file yang hash-nya disegel.'
                      : 'Isi file berbeda dari file yang hash-nya disegel.',
                ),
                const SizedBox(height: 8),
                Text(verification.title),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text(
                    'Detail teknis',
                    style: TextStyle(fontSize: 13),
                  ),
                  children: [SelectableText(verification.lines.join('\n\n'))],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } on ChecklistDocumentException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (e) {
      if (mounted) showSnack(context, 'Verifikasi dokumen gagal: $e');
    }
  }

  Future<void> _deleteDocument(ChecklistDocument document) async {
    final confirmed = await confirmDelete(context, document.fileName);
    if (confirmed != true) return;
    setState(() => _documentBusy = true);
    try {
      await _documentService.delete(document);
      await _load();
      if (mounted) {
        showSnack(
          context,
          'Dokumen dihapus. Catatan blockchain yang sudah dibuat tetap ada.',
        );
      }
    } on ChecklistDocumentException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (e) {
      if (mounted) showSnack(context, 'Dokumen gagal dihapus: $e');
    } finally {
      if (mounted) setState(() => _documentBusy = false);
    }
  }

  String _formatBytes(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).ceil()} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  Future<void> _save(ChecklistItem item) async {
    if (item.id == null) {
      await AppDb.instance.insert('checklist', item.toMap());
    } else {
      await AppDb.instance.update('checklist', item.id!, item.toMap());
    }
    await NotificationService.instance.rescheduleAll();
    await _load();
  }

  void _openProof() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ProgressProofScreen()),
  );

  Future<void> _toggle(ChecklistItem it) async {
    await AppDb.instance.update('checklist', it.id!, {'done': it.done ? 0 : 1});
    await NotificationService.instance.rescheduleAll();
    await _load();
  }

  Future<void> _delete(ChecklistItem it) async {
    try {
      if (it.rid != null) {
        final rows = await AppDb.instance.query(
          'checklist_documents',
          orderBy: 'created_at DESC',
        );
        final docs = rows
            .where((row) => row['checklist_rid'] == it.rid)
            .map(ChecklistDocument.fromMap)
            .toList();
        for (final document in docs) {
          await _documentService.delete(document);
        }
      }
      await AppDb.instance.delete('checklist', it.id!);
      await NotificationService.instance.rescheduleAll();
      await _load();
    } on ChecklistDocumentException catch (e) {
      if (mounted) showSnack(context, e.message);
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, 'Checklist gagal dihapus: $e');
      await _load();
    }
  }

  Future<void> _form([ChecklistItem? existing]) async {
    final title = TextEditingController(text: existing?.title ?? '');
    String category = existing?.category ?? kCategories.first;
    DateTime? deadline = existing?.deadline;
    String? error;

    await showFormSheet<void>(
      context,
      (c) => StatefulBuilder(
        builder: (c, setS) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null ? 'Tambah Tugas' : 'Ubah Tugas',
                style: Theme.of(c).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: title,
                decoration: InputDecoration(
                  labelText: 'Nama tugas',
                  errorText: error,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [
                  for (final k in kCategories)
                    DropdownMenuItem(value: k, child: Text(k)),
                ],
                onChanged: (v) => setS(() => category = v ?? category),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event),
                      label: Text(
                        deadline == null
                            ? 'Tanpa deadline'
                            : dateFmt.format(deadline!),
                      ),
                      onPressed: () async {
                        final p = await showDatePicker(
                          context: c,
                          initialDate: deadline ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 6),
                          ),
                        );
                        if (p != null) setS(() => deadline = p);
                      },
                    ),
                  ),
                  if (deadline != null)
                    IconButton(
                      onPressed: () => setS(() => deadline = null),
                      icon: const Icon(Icons.clear),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (title.text.trim().isEmpty) {
                    setS(() => error = 'Nama tugas wajib diisi');
                    return;
                  }
                  await _save(
                    ChecklistItem(
                      id: existing?.id,
                      title: title.text.trim(),
                      category: category,
                      deadline: deadline,
                      done: existing?.done ?? false,
                    ),
                  );
                  if (c.mounted) Navigator.pop(c);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _icon(String c) => switch (c) {
    'Dokumen' => Icons.description_outlined,
    'Keuangan' => Icons.payments_outlined,
    'Akademik' => Icons.school_outlined,
    'Akomodasi' => Icons.home_work_outlined,
    'Kesehatan' => Icons.health_and_safety_outlined,
    _ => Icons.label_outline,
  };

  @override
  Widget build(BuildContext context) {
    final done = _items.where((e) => e.done).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist Persiapan'),
        actions: [
          IconButton(
            tooltip: 'Bukti progres',
            icon: const Icon(Icons.verified_outlined),
            onPressed: _openProof,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const EmptyState(
              icon: Icons.checklist,
              message:
                  'Belum ada tugas persiapan.\nKetuk "Tambah" untuk memulai.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text('$done dari ${_items.length} selesai'),
                ),
                if (done == _items.length)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SoftCard(
                      color: kTealTint,
                      shadow: false,
                      onTap: _openProof,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: kPrimary,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Semua tugas selesai! Segel progresmu sebagai bukti.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: kSecondary),
                        ],
                      ),
                    ),
                  ),
                for (final it in _items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: ValueKey('cl-${it.id}'),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => confirmDelete(context, it.title),
                      onDismissed: (_) => _delete(it),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: kDanger,
                          borderRadius: BorderRadius.circular(kCardRadius),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: _tile(it),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _tile(ChecklistItem it) {
    final d = it.deadline == null ? null : daysUntil(it.deadline!);
    final late = !it.done && d != null && d < 0;
    final documents = it.rid == null
        ? const <ChecklistDocument>[]
        : _documents[it.rid] ?? const [];
    return SoftCard(
      onTap: () => _form(it),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: it.done,
            activeColor: kPrimary,
            onChanged: (_) => _toggle(it),
          ),
          Icon(_icon(it.category), color: kSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  it.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: it.done ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  it.deadline == null
                      ? it.category
                      : '${it.category} • ${dateFmt.format(it.deadline!)}${late ? ' • terlambat' : ''}',
                  style: TextStyle(fontSize: 12, color: late ? kDanger : null),
                ),
              ],
            ),
          ),
          if (it.category == 'Dokumen' || documents.isNotEmpty)
            IconButton(
              tooltip: 'Dokumen (${documents.length})',
              onPressed: _documentBusy ? null : () => _manageDocuments(it),
              icon: Badge(
                isLabelVisible: documents.isNotEmpty,
                label: Text('${documents.length}'),
                child: const Icon(Icons.attach_file),
              ),
            ),
        ],
      ),
    );
  }
}
