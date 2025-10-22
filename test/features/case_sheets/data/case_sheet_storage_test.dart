import 'dart:typed_data';

import 'package:cliniqflow/features/case_sheets/data/case_sheet_storage.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaseSheetStorageService', () {
    late MockFirebaseStorage storage;
    late CaseSheetStorageService service;

    setUp(() {
      storage = MockFirebaseStorage();
      service = CaseSheetStorageService(storage: storage);
    });

    test('uploadAttachment stores file and returns metadata', () async {
      final bytes = Uint8List.fromList(List<int>.generate(256, (index) => index % 255));

      final attachment = await service.uploadAttachment(
        caseSheetId: 'cs-123',
        fileName: 'xray.png',
        bytes: bytes,
        contentType: 'image/png',
      );

      expect(attachment.fileName, 'xray.png');
      expect(attachment.contentType, 'image/png');
      expect(attachment.sizeBytes, bytes.length);
      expect(attachment.uploadedAt, isNotNull);
      expect(attachment.downloadUrl, isNotEmpty);
      expect(attachment.storagePath, startsWith('case_sheets/cs-123/'));

      final storedData = await storage.ref(attachment.storagePath).getData();
      expect(storedData, isNotNull);
      expect(storedData, bytes);

      final metadata = await storage.ref(attachment.storagePath).getMetadata();
      expect(metadata.contentType, 'image/png');
    });

    test('deleteAttachment removes file from storage', () async {
      final bytes = Uint8List.fromList(List<int>.filled(32, 1));
      final attachment = await service.uploadAttachment(
        caseSheetId: 'cs-456',
        fileName: 'photo.jpg',
        bytes: bytes,
        contentType: 'image/jpeg',
      );

      await service.deleteAttachment(attachment);

      final contents = await storage.ref('case_sheets/cs-456').listAll();
      expect(contents.items, isEmpty);
    });
  });
}
