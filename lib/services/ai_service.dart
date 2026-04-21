import 'package:flutter/foundation.dart' show debugPrint;
import '../config/constants.dart';
import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ FIX: was AppConstants.nanoBananaProUrl (typo - doesn't exist)
  // Correct getter name: AppConstants.nanoBanaProUrl
  static String get _geminiUrl      => AppConstants.geminiUrl;
  static String get _imageNanoUrl   => AppConstants.imageNanoUrl;
  static String get _deepSeekUrl    => AppConstants.deepSeekUrl;
  static String get _nanoBanaProUrl => AppConstants.nanoBanaProUrl; // ✅ FIXED TYPO
  static String get _seedanceUrl    => AppConstants.seedanceUrl;
  static String get _musicAiUrl     => AppConstants.musicAiUrl;
  static const String _videoKilwaUrl = 'http://de3.bot-hosting.net:21007/kilwa-video';

  static const List<Map<String, dynamic>> seedanceModels = [
    {
      'id': 'Seedance 1.5 Pro',
      'name': 'Seedance 1.5 Pro',
      'durations': [4, 8, 12],
      'resolutions': ['480p', '720p'],
      'ratios': ['16:9', '9:16', '1:1', '4:3', '3:4', '21:9'],
      'supportsImageInput': true,
      'hasAudio': false,
    },
    {
      'id': 'Seedance 1.0 Pro',
      'name': 'Seedance 1.0 Pro',
      'durations': [5, 10],
      'resolutions': ['480p', '720p'],
      'ratios': ['16:9', '9:16', '1:1', '4:3', '3:4', '21:9'],
      'supportsImageInput': true,
      'hasAudio': false,
    },
    {
      'id': 'Seedance 1.0 Lite',
      'name': 'Seedance 1.0 Lite',
      'durations': [5, 10],
      'resolutions': ['480p', '720p'],
      'ratios': ['16:9', '9:16', '1:1', '4:3', '3:4', '21:9'],
      'supportsImageInput': true,
      'hasAudio': false,
    },
  ];

  static const List<String> imageRatios = ['1:1', '16:9', '9:16', '4:3', '3:4'];
  static const List<String> imageResolutions = ['1K', '2K', '4K'];
  static const List<Map<String, String>> deepSeekModels = [
    {'id': '1', 'name': 'DeepSeek V3.2'},
    {'id': '2', 'name': 'DeepSeek R1'},
    {'id': '3', 'name': 'DeepSeek Coder'},
  ];

  // ── Retry helper ──────────────────────────────────────────────────────
  Future<T> _withRetry<T>(Future<T> Function() fn, {int maxAttempts = 3, Duration delay = const Duration(seconds: 2)}) async {
    Exception? lastError;
    for (int i = 0; i < maxAttempts; i++) {
      try {
        return await fn();
      } on TimeoutException catch (e) {
        lastError = Exception('انتهت مهلة الاتصال، جاري إعادة المحاولة...');
        debugPrint('[AI] Timeout attempt ${i+1}: $e');
        if (i < maxAttempts - 1) await Future.delayed(delay * (i + 1));
      } on Exception catch (e) {
        final msg = e.toString();
        // Don't retry on business logic errors
        if (msg.contains('غير متاحة') || msg.contains('فشل') || msg.contains('خطأ')) rethrow;
        lastError = e;
        debugPrint('[AI] Error attempt ${i+1}: $e');
        if (i < maxAttempts - 1) await Future.delayed(delay);
      }
    }
    throw lastError ?? Exception('تعذر الاتصال بالخدمة');
  }

  // ── Service availability ──────────────────────────────────────────────
  Future<bool> _isServiceEnabled(String service) async {
    try {
      final doc = await _db.collection('settings').doc('ai_services')
          .get().timeout(const Duration(seconds: 5));
      if (!doc.exists) return true;
      return (doc.data() as Map<String, dynamic>)[service] ?? true;
    } catch (_) {
      return true; // Default to enabled if can't check
    }
  }

  Future<void> _log(String userId, String service, String prompt, bool success, [Map<String, dynamic>? extra]) async {
    try {
      await _db.collection(AppConstants.colAiLogs).add({
        'userId': userId,
        'service': service,
        'prompt': prompt.length > 500 ? prompt.substring(0, 500) : prompt,
        'success': success,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'extra': extra,
      }).timeout(const Duration(seconds: 5));
    } catch (e) { debugPrint('[AI.log] $e'); }
  }

  // ── Gemini Chat ───────────────────────────────────────────────────────
  Future<String> geminiChat(String message, String userId) async {
    if (!await _isServiceEnabled('gemini')) throw Exception('الخدمة غير متاحة حاليا');
    return _withRetry(() async {
      final res = await http.get(
        Uri.parse('$_geminiUrl?text=${Uri.encodeComponent(message)}'),
      ).timeout(const Duration(seconds: 35));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final reply = data['reply'] as String?;
        if (data['status'] == 'success' && reply != null && reply.isNotEmpty) {
          await _log(userId, 'gemini', message, true);
          return reply;
        }
        final errMsg = data['message'] ?? data['error'] ?? 'حدث خطأ في المعالجة';
        throw Exception(errMsg.toString());
      }
      throw Exception('خطأ في الخادم (${res.statusCode})');
    });
  }

  // ── DeepSeek Chat ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> deepSeekChat(String message, String userId, {String model = '1', String? conversationId}) async {
    if (!await _isServiceEnabled('deepseek')) throw Exception('الخدمة غير متاحة حاليا');
    return _withRetry(() async {
      final body = <String, String>{'model': model, 'message': message};
      if (conversationId != null) body['conversation_id'] = conversationId;
      final res = await http.post(
        Uri.parse(_deepSeekUrl),
        body: body,
      ).timeout(const Duration(seconds: 50));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final response = data['response'] as String?;
          if (response != null && response.isNotEmpty) {
            await _log(userId, 'deepseek', message, true, {'model': model});
            return {
              'response': response,
              'conversation_id': data['conversation_id'] as String? ?? '',
            };
          }
        }
        throw Exception(data['message']?.toString() ?? 'حدث خطأ في المعالجة');
      }
      throw Exception('خطأ في الخادم (${res.statusCode})');
    });
  }

  // ── Nano Banana 2 Image Generation ───────────────────────────────────
  Future<String> generateImageNano(String prompt, String userId) async {
    if (!await _isServiceEnabled('imageGen')) throw Exception('الخدمة غير متاحة حاليا');
    return _withRetry(() async {
      final res = await http.get(
        Uri.parse('$_imageNanoUrl?text=${Uri.encodeComponent(prompt)}'),
      ).timeout(const Duration(seconds: 65));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final url = data['image_url'] as String?;
        if (data['status'] == 'success' && url != null && url.isNotEmpty) {
          await _log(userId, 'imageGen', prompt, true, {'url': url});
          return url;
        }
        throw Exception(data['message']?.toString() ?? 'فشل توليد الصورة');
      }
      throw Exception('خطأ في الخادم (${res.statusCode})');
    });
  }

  // ── NanoBanana Pro - create or edit image ────────────────────────────
  Future<String> nanoBananaPro({
    required String prompt,
    required String userId,
    String ratio = '1:1',
    String resolution = '2K',
    String? imageUrl,
    List<String>? imageUrls,
  }) async {
    if (!await _isServiceEnabled('nanoBananaPro')) throw Exception('الخدمة غير متاحة حاليا');
    return _withRetry(() async {
      final request = http.MultipartRequest('POST', Uri.parse(_nanoBanaProUrl));
      request.fields['text'] = prompt;
      request.fields['ratio'] = ratio;
      request.fields['res'] = resolution;
      if (imageUrls != null && imageUrls.isNotEmpty) {
        request.fields['links'] = imageUrls.length == 1 ? imageUrls.first : jsonEncode(imageUrls);
      } else if (imageUrl != null && imageUrl.isNotEmpty) {
        request.fields['links'] = imageUrl;
      }
      final streamed = await request.send().timeout(const Duration(seconds: 95));
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final url = data['url'] as String?;
        if (data['success'] == true && url != null && url.isNotEmpty) {
          await _log(userId, 'nanoBananaPro', prompt, true, {'url': url, 'mode': data['mode']});
          return url;
        }
        throw Exception(data['message']?.toString() ?? 'فشل معالجة الصورة');
      }
      throw Exception('خطأ في الخادم (${res.statusCode})');
    }, maxAttempts: 2); // fewer retries for expensive operations
  }

  // ── Video generation with Kilwa API ──────────────────────────────────
  Future<String> generateVideoKilwa(String prompt, String userId) async {
    if (!await _isServiceEnabled('videoGen')) throw Exception('الخدمة غير متاحة حاليا');
    return _withRetry(() async {
      final res = await http.get(
        Uri.parse('$_videoKilwaUrl?text=${Uri.encodeComponent(prompt)}'),
      ).timeout(const Duration(seconds: 130));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final url = data['video_url'] as String?;
        if (data['status'] == 'success' && url != null && url.isNotEmpty) {
          await _log(userId, 'kilwaVideo', prompt, true, {'url': url});
          return url;
        }
        throw Exception(data['message']?.toString() ?? 'فشل توليد الفيديو');
      }
      throw Exception('خطأ في الخادم (${res.statusCode})');
    }, maxAttempts: 2);
  }

  // ── Seedance Video Generation ─────────────────────────────────────────
  Future<String> seedanceGenerate({
    required String prompt,
    required String userId,
    String model = 'Seedance 1.5 Pro',
    int duration = 8,
    String resolution = '720p',
    String aspectRatio = '16:9',
    String? imageUrl,
  }) async {
    if (!await _isServiceEnabled('seedance')) throw Exception('الخدمة غير متاحة حاليا');
    return _withRetry(() async {
      final body = <String, dynamic>{
        'prompt': prompt,
        'model': model,
        'duration': duration,
        'resolution': resolution,
        'aspect_ratio': aspectRatio,
      };
      if (imageUrl != null && imageUrl.isNotEmpty) body['image_url'] = imageUrl;
      final res = await http.post(
        Uri.parse(_seedanceUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 190));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final videoUrl = (data['data'] as Map<String, dynamic>?)?['video_url'] as String?;
          if (videoUrl != null && videoUrl.isNotEmpty) {
            await _log(userId, 'seedance', prompt, true, {'url': videoUrl, 'model': model, 'duration': duration});
            return videoUrl;
          }
        }
        throw Exception(data['message']?.toString() ?? 'فشل توليد الفيديو');
      }
      throw Exception('خطأ في الخادم (${res.statusCode})');
    }, maxAttempts: 2);
  }

  // ── Music AI ─────────────────────────────────────────────────────────
  Future<String> generateMusic({required String prompt, required String userId, String style = 'pop'}) async {
    if (!await _isServiceEnabled('musicAi')) throw Exception('الخدمة غير متاحة حاليا');
    return _withRetry(() async {
      final res = await http.post(
        Uri.parse(_musicAiUrl),
        body: {'prompt': prompt, 'style': style},
      ).timeout(const Duration(seconds: 90));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final url = data['url'] as String? ?? data['audio_url'] as String?;
        if (url != null && url.isNotEmpty) {
          await _log(userId, 'musicAi', prompt, true, {'url': url, 'style': style});
          return url;
        }
        throw Exception(data['message']?.toString() ?? 'فشل توليد الموسيقى');
      }
      throw Exception('خطأ في الخادم (${res.statusCode})');
    }, maxAttempts: 2);
  }

  // ── Admin: Toggle service ──────────────────────────────────────────────
  Future<void> toggleService(String service, bool enabled) async {
    await _db.collection('settings').doc('ai_services')
        .set({service: enabled}, SetOptions(merge: true));
  }

  Future<Map<String, bool>> getServiceStates() async {
    try {
      final doc = await _db.collection('settings').doc('ai_services').get()
          .timeout(const Duration(seconds: 8));
      if (!doc.exists) return _defaults();
      final d = doc.data() as Map<String, dynamic>;
      return {
        'gemini':        d['gemini']        ?? true,
        'deepseek':      d['deepseek']      ?? true,
        'imageGen':      d['imageGen']      ?? true,
        'nanoBananaPro': d['nanoBananaPro'] ?? true,
        'kilwaVideo':    d['kilwaVideo']    ?? true,
        'seedance':      d['seedance']      ?? true,
        'musicAi':       d['musicAi']       ?? true,
      };
    } catch (_) { return _defaults(); }
  }

  Map<String, bool> _defaults() => {
    'gemini': true, 'deepseek': true, 'imageGen': true,
    'nanoBananaPro': true, 'kilwaVideo': true, 'seedance': true, 'musicAi': true,
  };

  Future<Map<String, int>> getUsageStats() async {
    final stats = <String, int>{
      'gemini': 0, 'deepseek': 0, 'imageGen': 0,
      'nanoBananaPro': 0, 'kilwaVideo': 0, 'seedance': 0, 'musicAi': 0, 'total': 0
    };
    try {
      final snap = await _db.collection(AppConstants.colAiLogs).get()
          .timeout(const Duration(seconds: 15));
      for (final d in snap.docs) {
        final s = d.data()['service'] as String? ?? '';
        if (stats.containsKey(s)) stats[s] = (stats[s] ?? 0) + 1;
        stats['total'] = (stats['total'] ?? 0) + 1;
      }
    } catch (e) { debugPrint('[AI.getUsageStats] $e'); }
    return stats;
  }

  Stream<List<Map<String, dynamic>>> logsStream() {
    return _db.collection(AppConstants.colAiLogs)
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'docId': d.id}).toList());
  }
}
