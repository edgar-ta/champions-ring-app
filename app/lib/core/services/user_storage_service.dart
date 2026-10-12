// Responsabilidad: Manejar el guardado y eliminación de datos no estructurados relativos al usuario
import 'dart:typed_data';

import 'package:champions_ring_app/core/utils/result.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

enum ImageUploadError {
  badInternet,
  unauthenticatedUser,
  unauthorizedUser,
  firebaseStorageQuotaExceeded,
  invalidFormat,
  emptyImage,
  fileTooLarge,
  canceled,
  storageConfiguration,
  other,
}

class UserStorageService {
  final String userId;

  UserStorageService({required this.userId});

  Reference get storage => FirebaseStorage.instance.ref();

  String _contentType(String format) => switch (format.toLowerCase()) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/$format',
  };

  Future<Result<ImageUploadError, String>> uploadIneBack(
    Uint8List bytes,
    String format,
  ) => _upload(
    bytes,
    format,
    path: 'users/$userId/ine_back',
    maxBytes: 20 * 1024 * 1024,
  );

  Future<Result<ImageUploadError, String>> uploadIneFront(
    Uint8List bytes,
    String format,
  ) => _upload(
    bytes,
    format,
    path: 'users/$userId/ine_front',
    maxBytes: 20 * 1024 * 1024,
  );

  Future<Result<ImageUploadError, String>> uploadProfilePicture(
    Uint8List bytes,
    String format,
  ) => _upload(
    bytes,
    format,
    path: 'users/$userId/profile_picture',
    maxBytes: 5 * 1024 * 1024,
  );

  Future<Result<ImageUploadError, String>> uploadSignature(
    Uint8List bytes,
    String format,
  ) => _upload(
    bytes,
    format,
    path: 'users/$userId/signature',
    maxBytes: 20 * 1024 * 1024,
  );

  Future<Result<ImageUploadError, String>> _upload(
    Uint8List bytes,
    String format, {
    required String path,
    required int maxBytes,
  }) async {
    final normalizedFormat = format.toLowerCase().replaceFirst('.', '');
    if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(normalizedFormat)) {
      return Error(errorType: ImageUploadError.invalidFormat);
    }
    if (bytes.isEmpty) {
      return Error(errorType: ImageUploadError.emptyImage);
    }
    if (bytes.length > maxBytes) {
      return Error(errorType: ImageUploadError.fileTooLarge);
    }

    try {
      final reference = storage.child('$path.$normalizedFormat');
      await reference.putData(
        bytes,
        SettableMetadata(contentType: _contentType(normalizedFormat)),
      );
      return Success(result: await reference.getDownloadURL());
    } on FirebaseException catch (exception) {
      return Error(
        errorType: _mapStorageError(exception.code),
        exception: exception,
      );
    } catch (exception) {
      return Error(
        errorType: ImageUploadError.other,
        exception: exception is Exception
            ? exception
            : Exception(exception.toString()),
      );
    }
  }

  ImageUploadError _mapStorageError(String code) => switch (code) {
    'retry-limit-exceeded' ||
    'network-request-failed' => ImageUploadError.badInternet,
    'unauthenticated' => ImageUploadError.unauthenticatedUser,
    'unauthorized' || 'permission-denied' => ImageUploadError.unauthorizedUser,
    'quota-exceeded' => ImageUploadError.firebaseStorageQuotaExceeded,
    'canceled' => ImageUploadError.canceled,
    'bucket-not-found' ||
    'no-default-bucket' ||
    'project-not-found' => ImageUploadError.storageConfiguration,
    _ => ImageUploadError.other,
  };
}
