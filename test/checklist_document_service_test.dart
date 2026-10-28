import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:studytrip/services/checklist_document_service.dart';

void main() {
  group('ChecklistDocumentService', () {
    test('hash dokumen memakai SHA-256 dari byte asli', () {
      expect(
        ChecklistDocumentService.hashBytes(utf8.encode('abc')),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('payload bukti mengambil hash dokumen tanpa memuat file', () {
      final payload = ChecklistDocumentService.payloadForSeal(
        '{"kind":"document","documentHash":"abc123"}',
      );

      expect(payload?['documentHash'], 'abc123');
      expect(ChecklistDocumentService.payloadForSeal('[]'), isNull);
    });
  });
}
