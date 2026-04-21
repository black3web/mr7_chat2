import 'package:flutter/foundation.dart' show debugPrint;
import '../config/constants.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class KilwaVideoService {
  static final KilwaVideoService _instance = KilwaVideoService._internal();
  factory KilwaVideoService() => _instance;
  KilwaVideoService._internal();

  static String get _baseUrl => AppConstants.kilwaVideoUrl;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> _isEnabled() async {
    try {
      final doc = await _db.collection('settings').doc('ai_services').get();
      if (!doc.exists) return true;
      return (doc.data() as Map<String, dynamic>)['kilwaVideo'] ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> _log(String userId, String prompt, bool success, [String? videoUrl]) async {
    try {
      await _db.collection('ai_logs').add({
        'userId': userId,
        'service': 'kilwaVideo',
        'prompt': prompt,
        'extra': {'videoUrl': videoUrl, 'model': 'Seedance 1.5 Pro'},
        'success': success,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) { debugPrint("[Kilwa Video Service] Error: $e"); }
  }

  /// Generate video from text prompt using Kilwa API
  /// Returns video URL on success
  Future<String> generateVideo({
    required String prompt,
    required String userId,
  }) async {
    if (!await _isEnabled()) {
      throw Exception('خدمة توليد الفيديو غير متاحة حاليا');
    }

    try {
      final uri = Uri.parse('$_baseUrl?text=${Uri.encodeComponent(prompt)}');
      final response = await http.get(uri)
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          final videoUrl = data['video_url'] as String?;
          if (videoUrl != null && videoUrl.isNotEmpty) {
            await _log(userId, prompt, true, videoUrl);
            return videoUrl;
          }
        }
      }
      throw Exception('فشل توليد الفيديو');
    } catch (e) {
      await _log(userId, prompt, false);
      if (e.toString().contains('فشل') || e.toString().contains('غير متاحة')) rethrow;
      throw Exception('تعذر الاتصال بخدمة توليد الفيديو');
    }
  }

  Stream<List<Map<String, dynamic>>> getUserVideoHistory(String userId) {
    return _db
        .collection('ai_logs')
        .where('userId', isEqualTo: userId)
        .where('service', isEqualTo: 'kilwaVideo')
        .where('success', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }
}