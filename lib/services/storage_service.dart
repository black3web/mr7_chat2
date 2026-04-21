import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();
  final _picker = ImagePicker();

  // ── File size limits ──────────────────────────────────────────────────
  static const int maxImageBytes  = 15 * 1024 * 1024; // 15 MB
  static const int maxVideoBytes  = 100 * 1024 * 1024; // 100 MB
  static const int maxFileBytes   = 50 * 1024 * 1024;  // 50 MB

  // ── Pick image from gallery or camera ────────────────────────────────
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      return await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
    } catch (e) {
      debugPrint('[Storage] pickImage error: $e');
      rethrow;
    }
  }

  // ── Pick video ────────────────────────────────────────────────────────
  Future<XFile?> pickVideo({ImageSource source = ImageSource.gallery}) async {
    try {
      return await _picker.pickVideo(source: source, maxDuration: const Duration(minutes: 5));
    } catch (e) {
      debugPrint('[Storage] pickVideo error: $e');
      rethrow;
    }
  }

  // ── Validate file size ────────────────────────────────────────────────
  Future<void> _validateSize(XFile file, int maxBytes, String label) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > maxBytes) {
        final mb = (maxBytes / 1024 / 1024).round();
        throw Exception('حجم $label كبير جداً. الحد الأقصى $mb MB');
      }
    } catch (e) {
      if (e.toString().contains('حجم')) rethrow;
      // If size check fails, proceed anyway
    }
  }

  // ── Upload helper ─────────────────────────────────────────────────────
  Future<String> _upload(XFile file, String storagePath, {String? contentType}) async {
    final ref = _storage.ref().child(storagePath);
    UploadTask task;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final meta = contentType != null
          ? SettableMetadata(contentType: contentType)
          : null;
      task = meta != null ? ref.putData(bytes, meta) : ref.putData(bytes);
    } else {
      task = ref.putFile(File(file.path));
    }

    try {
      final snapshot = await task.timeout(const Duration(minutes: 5));
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('[Storage] Firebase upload error: ${e.code} - ${e.message}');
      if (e.code == 'storage/unauthorized') throw Exception('غير مصرح لك برفع الملفات');
      if (e.code == 'storage/quota-exceeded') throw Exception('تجاوز حد التخزين');
      if (e.code == 'storage/canceled') throw Exception('تم إلغاء الرفع');
      throw Exception('فشل رفع الملف: ${e.message}');
    } catch (e) {
      debugPrint('[Storage] Upload error: $e');
      throw Exception('تعذر رفع الملف. تحقق من الاتصال');
    }
  }

  // ── Upload profile photo ──────────────────────────────────────────────
  Future<String> uploadProfilePhoto(XFile file) async {
    await _validateSize(file, maxImageBytes, 'الصورة');
    final ext = path.extension(file.name).toLowerCase();
    final fileName = '${_uuid.v4()}${ext.isEmpty ? '.jpg' : ext}';
    return _upload(file, 'profile_photos/$fileName', contentType: 'image/jpeg');
  }

  // ── Upload chat media (image or video) ────────────────────────────────
  Future<String> uploadMedia(XFile file, String chatId) async {
    final ext = path.extension(file.name).toLowerCase();
    final isVideo = ['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(ext);
    await _validateSize(file, isVideo ? maxVideoBytes : maxImageBytes, isVideo ? 'الفيديو' : 'الصورة');
    final fileName = '${_uuid.v4()}${ext.isEmpty ? '.jpg' : ext}';
    return _upload(file, 'chat_media/$chatId/$fileName');
  }

  // ── Upload bytes ──────────────────────────────────────────────────────
  Future<String> uploadBytes(Uint8List bytes, String folder, String extension) async {
    final fileName = '${_uuid.v4()}.$extension';
    final ref = _storage.ref().child('$folder/$fileName');
    try {
      final task = ref.putData(bytes);
      final snapshot = await task.timeout(const Duration(minutes: 3));
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('[Storage] uploadBytes: $e');
      throw Exception('فشل رفع البيانات');
    }
  }

  // ── Upload story media ────────────────────────────────────────────────
  Future<String> uploadStoryMedia(XFile file, String userId) async {
    await _validateSize(file, maxVideoBytes, 'الوسائط');
    final ext = path.extension(file.name);
    final fileName = '${_uuid.v4()}${ext.isEmpty ? '.jpg' : ext}';
    return _upload(file, 'stories/$userId/$fileName');
  }

  // ── Upload sticker ────────────────────────────────────────────────────
  Future<String> uploadSticker(XFile file, String userId, String packId) async {
    await _validateSize(file, maxImageBytes, 'الملصق');
    final ext = path.extension(file.name);
    final fileName = '${_uuid.v4()}${ext.isEmpty ? '.png' : ext}';
    return _upload(file, 'stickers/$userId/$packId/$fileName');
  }

  // ── Upload group photo ────────────────────────────────────────────────
  Future<String> uploadGroupPhoto(XFile file, String groupId) async {
    await _validateSize(file, maxImageBytes, 'صورة المجموعة');
    final ext = path.extension(file.name);
    final fileName = '${_uuid.v4()}${ext.isEmpty ? '.jpg' : ext}';
    return _upload(file, 'group_photos/$groupId/$fileName', contentType: 'image/jpeg');
  }

  // ── Upload support image ──────────────────────────────────────────────
  Future<String> uploadSupportImage(XFile file, String userId) async {
    await _validateSize(file, maxImageBytes, 'الصورة');
    final ext = path.extension(file.name);
    final fileName = '${_uuid.v4()}${ext.isEmpty ? '.jpg' : ext}';
    return _upload(file, 'support/$userId/$fileName');
  }

  // ── Delete file by URL ────────────────────────────────────────────────
  Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete().timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('[Storage] deleteByUrl error: $e');
    }
  }

  // ── Get storage usage size ────────────────────────────────────────────
  Future<int> getFileSizeBytes(XFile file) async {
    try {
      if (!kIsWeb) {
        final f = File(file.path);
        return await f.length();
      }
      final bytes = await file.readAsBytes();
      return bytes.length;
    } catch (_) {
      return 0;
    }
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
