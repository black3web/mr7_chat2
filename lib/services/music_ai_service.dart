import 'package:flutter/foundation.dart' show debugPrint;
import '../config/constants.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class MusicAiService {
  static final MusicAiService _instance = MusicAiService._internal();
  factory MusicAiService() => _instance;
  MusicAiService._internal();

  static String get _baseUrl => AppConstants.musicAiUrl;

  static const List<Map<String, String>> supportedTags = [
    {'id': 'sad',       'label': 'حزين',     'labelEn': 'Sad'},
    {'id': 'happy',     'label': 'سعيد',     'labelEn': 'Happy'},
    {'id': 'romantic',  'label': 'رومانسي',  'labelEn': 'Romantic'},
    {'id': 'energetic', 'label': 'حماسي',    'labelEn': 'Energetic'},
  ];

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> _isEnabled() async {
    try {
      final doc = await _db.collection('settings').doc('ai_services').get();
      if (!doc.exists) return true;
      return (doc.data() as Map<String, dynamic>)['musicAi'] ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> _log(String userId, String prompt, String tag, bool success, [String? audioUrl]) async {
    try {
      await _db.collection('ai_logs').add({
        'userId': userId,
        'service': 'musicAi',
        'prompt': prompt,
        'extra': {'tag': tag, 'audioUrl': audioUrl},
        'success': success,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) { debugPrint("[Music Ai Service] Error: $e"); }
  }

  /// Generate music from text prompt
  /// Returns audioUrl on success
  Future<String> generateMusic({
    required String prompt,
    required String userId,
    String tag = 'sad',
  }) async {
    if (!await _isEnabled()) {
      throw Exception('خدمة الموسيقى غير متاحة حاليا');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'tags': tag,
          'chat_id': userId,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final audioUrl = data['audio_url'] as String?;
          if (audioUrl != null && audioUrl.isNotEmpty) {
            await _log(userId, prompt, tag, true, audioUrl);
            return audioUrl;
          }
        }
      }
      throw Exception('فشل توليد الموسيقى');
    } catch (e) {
      await _log(userId, prompt, tag, false);
      if (e.toString().contains('فشل') || e.toString().contains('غير متاحة')) rethrow;
      throw Exception('تعذر الاتصال بخدمة الموسيقى');
    }
  }

  Stream<List<Map<String, dynamic>>> getUserMusicHistory(String userId) {
    return _db
        .collection('ai_logs')
        .where('userId', isEqualTo: userId)
        .where('service', isEqualTo: 'musicAi')
        .where('success', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }
}