import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/current_user.dart';
import '../data/app_db.dart';

const checklistDocumentsBucket = 'checklist-documents';
const checklistDocumentMaxBytes = 10 * 1024 * 1024;

class ChecklistDocumentException implements Exception {
  final String message;
  const ChecklistDocumentException(this.message);

  @override
  String toString() => message;
}

class ChecklistDocument {
  final int id;
  final String checklistRid;
  final String fileName;
  final String storagePath;
  final String contentType;
  final String fileHash;
  final int fileSize;
  final DateTime createdAt;

  const ChecklistDocument({
    required this.id,
    required this.checklistRid,
    required this.fileName,
    required this.storagePath,
    required this.contentType,
    required this.fileHash,
    required this.fileSize,
    required this.createdAt,
  });

  factory ChecklistDocument.fromMap(Map<String, Object?> row) =>
      ChecklistDocument(
        id: row['id'] as int,
        checklistRid: row['checklist_rid'] as String,
        fileName: row['file_name'] as String,
        storagePath: row['storage_path'] as String,
        contentType: row['content_type'] as String,
        fileHash: row['file_hash'] as String,
        fileSize: row['file_size'] as int,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}

class ChecklistDocumentService {
  ChecklistDocumentService._();
  static final ChecklistDocumentService instance = ChecklistDocumentService._();

  SupabaseClient get _client {
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser == null) {
        throw const ChecklistDocumentException(
          'Silakan masuk ke akun cloud saat internet aktif untuk mengelola dokumen.',
        );
      }
      if (CurrentUser.id == null) {
        throw const ChecklistDocumentException(
          'Masuk ke akun terlebih dahulu.',
        );
      }
      return client;
    } on ChecklistDocumentException {
      rethrow;
    } catch (_) {
      throw const ChecklistDocumentException(
        'Layanan cloud belum aktif di aplikasi ini.',
      );
    }
  }

  Future<List<ChecklistDocument>> listForChecklist(String checklistRid) async {
    final localRows = await AppDb.instance.query(
      'checklist_documents',
      orderBy: 'created_at DESC',
    );
    final cached = localRows
        .where((row) => row['checklist_rid'] == checklistRid)
        .toList();
    SupabaseClient client;
    try {
      client = _client;
    } on ChecklistDocumentException {
      return cached.map(ChecklistDocument.fromMap).toList();
    }

    final List<Map<String, dynamic>> remoteRows;
    try {
      remoteRows = await client
          .from('checklist_documents')
          .select()
          .eq('checklist_rid', checklistRid)
          .order('created_at', ascending: false);
    } on PostgrestException catch (e) {
      throw ChecklistDocumentException(
        'Metadata dokumen gagal dimuat: ${e.message}',
      );
    } catch (e) {
      throw ChecklistDocumentException('Metadata dokumen gagal dimuat: $e');
    }

    final remotePaths = <String>{};

    for (final remote in remoteRows) {
      final path = remote['storage_path'] as String;
      remotePaths.add(path);
      if (cached.any((row) => row['storage_path'] == path)) continue;
      await AppDb.instance.insert('checklist_documents', {
        'checklist_rid': checklistRid,
        'file_name': remote['file_name'],
        'storage_path': path,
        'content_type': remote['content_type'],
        'file_hash': remote['file_hash'],
        'file_size': remote['file_size'],
        'created_at': remote['created_at'],
      });
    }

    for (final row in cached) {
      if (!remotePaths.contains(row['storage_path'])) {
        await AppDb.instance.delete('checklist_documents', row['id'] as int);
      }
    }

    final refreshed = await AppDb.instance.query(
      'checklist_documents',
      orderBy: 'created_at DESC',
    );
    return refreshed
        .where((row) => row['checklist_rid'] == checklistRid)
        .map(ChecklistDocument.fromMap)
        .toList();
  }

  Future<ChecklistDocument> upload({
    required String checklistRid,
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty) {
      throw const ChecklistDocumentException(
        'File kosong tidak dapat diunggah.',
      );
    }
    if (bytes.length > checklistDocumentMaxBytes) {
      throw const ChecklistDocumentException(
        'Ukuran maksimal dokumen adalah 10 MB.',
      );
    }
    if (checklistRid.isEmpty) {
      throw const ChecklistDocumentException(
        'Checklist belum tersinkron dan belum memiliki ID.',
      );
    }

    final extension = fileName.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw const ChecklistDocumentException(
        'Format yang didukung: PDF, JPG, PNG, atau WEBP.',
      ),
    };

    final client = _client;
    final hash = sha256.convert(bytes).toString();
    final uid = client.auth.currentUser!.id;
    final path =
        '$uid/$checklistRid/${DateTime.now().microsecondsSinceEpoch}-${hash.substring(0, 12)}.$extension';
    final createdAt = DateTime.now().toUtc().toIso8601String();

    try {
      await client.storage
          .from(checklistDocumentsBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );
    } on StorageException catch (e) {
      throw ChecklistDocumentException('Dokumen gagal diunggah: ${e.message}');
    }

    try {
      await client.from('checklist_documents').insert({
        'user_id': uid,
        'checklist_rid': checklistRid,
        'file_name': fileName,
        'storage_path': path,
        'content_type': contentType,
        'file_hash': hash,
        'file_size': bytes.length,
        'created_at': createdAt,
      });
      final id = await AppDb.instance.insert('checklist_documents', {
        'checklist_rid': checklistRid,
        'file_name': fileName,
        'storage_path': path,
        'content_type': contentType,
        'file_hash': hash,
        'file_size': bytes.length,
        'created_at': createdAt,
      });
      return ChecklistDocument(
        id: id,
        checklistRid: checklistRid,
        fileName: fileName,
        storagePath: path,
        contentType: contentType,
        fileHash: hash,
        fileSize: bytes.length,
        createdAt: DateTime.parse(createdAt),
      );
    } catch (e) {
      try {
        await client
            .from('checklist_documents')
            .delete()
            .eq('storage_path', path);
        await client.storage.from(checklistDocumentsBucket).remove([path]);
      } catch (cleanupError) {
        throw ChecklistDocumentException(
          'Metadata dokumen gagal disimpan dan file sementara gagal dibersihkan: $cleanupError',
        );
      }
      if (e is PostgrestException) {
        throw ChecklistDocumentException(
          'Metadata dokumen gagal disimpan: ${e.message}',
        );
      }
      rethrow;
    }
  }

  Future<Uint8List> download(ChecklistDocument document) async {
    try {
      return await _client.storage
          .from(checklistDocumentsBucket)
          .download(document.storagePath);
    } on StorageException catch (e) {
      throw ChecklistDocumentException('Dokumen gagal diunduh: ${e.message}');
    }
  }

  Future<String> signedUrl(ChecklistDocument document) async {
    try {
      return await _client.storage
          .from(checklistDocumentsBucket)
          .createSignedUrl(document.storagePath, 60);
    } on StorageException catch (e) {
      throw ChecklistDocumentException(
        'Tautan dokumen gagal dibuat: ${e.message}',
      );
    }
  }

  Future<void> delete(ChecklistDocument document) async {
    final client = _client;
    try {
      await client.storage.from(checklistDocumentsBucket).remove([
        document.storagePath,
      ]);
    } on StorageException catch (e) {
      throw ChecklistDocumentException('Dokumen gagal dihapus: ${e.message}');
    }
    try {
      await client
          .from('checklist_documents')
          .delete()
          .eq('storage_path', document.storagePath);
    } on PostgrestException catch (e) {
      throw ChecklistDocumentException(
        'File terhapus, tetapi metadata dokumen gagal diperbarui: ${e.message}',
      );
    }
    await AppDb.instance.delete('checklist_documents', document.id);
  }

  static String hashBytes(List<int> bytes) => sha256.convert(bytes).toString();

  static Map<String, dynamic>? payloadForSeal(String payload) {
    final decoded = jsonDecode(payload);
    return decoded is Map<String, dynamic> ? decoded : null;
  }
}
