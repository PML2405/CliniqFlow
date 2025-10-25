import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../models/case_sheet.dart';

class CaseSheetStorageService {
  CaseSheetStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<CaseSheetAttachment> uploadAttachment({
    required String caseSheetId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = 'case_sheets/$caseSheetId/${timestamp}_$sanitizedName';
    final ref = _storage.ref(path);

    final metadata = SettableMetadata(
      contentType: contentType,
      cacheControl: 'public, max-age=604800',
    );

    await ref.putData(bytes, metadata);

    final downloadUrl = await ref.getDownloadURL();
    final currentMetadata = await ref.getMetadata();

    return CaseSheetAttachment(
      id: ref.name,
      storagePath: path,
      fileName: fileName,
      downloadUrl: downloadUrl,
      contentType: currentMetadata.contentType,
      sizeBytes: currentMetadata.size,
      uploadedAt: currentMetadata.timeCreated?.toLocal(),
    );
  }

  Future<void> deleteAttachment(CaseSheetAttachment attachment) {
    return _storage.ref(attachment.storagePath).delete();
  }
}
