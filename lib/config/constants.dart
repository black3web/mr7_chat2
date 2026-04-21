class AppConstants {
  // App Info
  static const String appName = 'MR7';
  static const String appFullName = 'MR7 Chat';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Developer account
  static const String devName = 'جلال';
  static const String devUsername = 'a1';
  static const String devPasswordRaw = '5cd9e55dcaf491d32289b848adeb216e';
  static const String devId = '000000000000001';
  static const String devWebsite = 'https://black3web.github.io/Blackweb/';
  static const String devTelegram = 'https://t.me/swc_t';

  // AI API Endpoints (never exposed to users)
  static const String _geminiUrl      = 'http://de3.bot-hosting.net:21007/kilwa-chat';
  static const String _imageNanoUrl   = 'http://de3.bot-hosting.net:21007/kilwa-img';
  static const String _kilwaVideoUrl  = 'http://de3.bot-hosting.net:21007/kilwa-video';
  static const String _deepSeekUrl    = 'https://zecora0.serv00.net/deepseek.php';
  static const String _nanoBanaProUrl = 'https://zecora0.serv00.net/ai/NanoBanana.php';
  static const String _seedanceUrl    = 'https://zecora0.serv00.net/ai/Seedance.php';
  static const String _musicAiUrl     = 'https://viscodev.x10.mx/musicai/api.php';

  // Public getters (used by services only)
  static String get geminiUrl      => _geminiUrl;
  static String get imageNanoUrl   => _imageNanoUrl;
  static String get kilwaVideoUrl  => _kilwaVideoUrl;
  static String get deepSeekUrl    => _deepSeekUrl;
  static String get nanoBanaProUrl => _nanoBanaProUrl;
  static String get seedanceUrl    => _seedanceUrl;
  static String get musicAiUrl     => _musicAiUrl;

  // Firestore collections
  static const String colUsers     = 'users';
  static const String colChats     = 'chats';
  static const String colGroups    = 'groups';
  static const String colStories   = 'stories';
  static const String colSupport   = 'support';
  static const String colBroadcast = 'broadcasts';
  static const String colAiLogs   = 'ai_logs';
  static const String colStickers  = 'stickers';
  static const String colNotifs    = 'notifications';

  // Story limits
  static const int storyDurationHours = 48;
  static const int maxStoriesPerCycle = 3;
  static const int maxStoryVideoSeconds = 300;

  // Message limits
  static const int maxMessageLength = 5000;
  static const int maxStickerVideoSec = 15;
  static const int maxStickersPerPack = 250;

  // Validation
  static const int minUsernameLen = 4;
  static const int maxUsernameLen = 25;
  static const int minPasswordLen = 4;
  static const int maxPasswordLen = 100;
  static const int maxNameLen = 50;
  static const String usernamePattern = r'^[a-zA-Z0-9_-]+$';

  // User ID
  static const int userIdLength = 15;

  // Seedance models
  static const List<Map<String, dynamic>> seedanceModels = [
    {
      'id': 'Seedance 1.5 Pro',
      'name': 'Seedance 1.5 Pro',
      'durations': [4, 8, 12],
      'resolutions': ['480p', '720p'],
      'ratios': ['16:9', '9:16', '1:1', '4:3', '3:4', '21:9'],
      'supportsImage': true,
    },
    {
      'id': 'Seedance 1.0 Pro',
      'name': 'Seedance 1.0 Pro',
      'durations': [5, 10],
      'resolutions': ['480p', '720p'],
      'ratios': ['16:9', '9:16', '1:1', '4:3', '3:4', '21:9'],
      'supportsImage': true,
    },
    {
      'id': 'Seedance 1.0 Lite',
      'name': 'Seedance 1.0 Lite',
      'durations': [5, 10],
      'resolutions': ['480p', '720p'],
      'ratios': ['16:9', '9:16', '1:1', '4:3', '3:4', '21:9'],
      'supportsImage': true,
    },
  ];

  // Image generation
  static const List<String> imageRatios = ['1:1', '16:9', '9:16', '4:3', '3:4'];
  static const List<String> imageResolutions = ['1K', '2K', '4K'];

  // DeepSeek models
  static const Map<String, String> deepSeekModels = {
    '1': 'DeepSeek V3.2',
    '2': 'DeepSeek R1',
    '3': 'DeepSeek Coder',
  };

  // AI service keys (for admin panel)
  static const List<String> aiServiceKeys = [
    'gemini', 'deepseek', 'imageGen', 'nanoBananaPro',
    'seedance', 'kilwaVideo', 'musicAi',
  ];

  static const Map<String, String> aiServiceNames = {
    'gemini':       'Gemini 2.5 Flash',
    'deepseek':     'DeepSeek AI',
    'imageGen':     'Nano Banana 2',
    'nanoBananaPro':'NanoBanana Pro',
    'seedance':     'Seedance AI',
    'kilwaVideo':   'Video AI',
    'musicAi':      'AI Music',
  };

  // Reaction emojis
  static const List<String> reactions = [
    '\u2764', '\uD83D\uDE02', '\uD83D\uDE22', '\uD83D\uDC4D',
    '\uD83D\uDE31', '\uD83D\uDD25', '\uD83E\uDD14', '\uD83D\uDC4F',
    '\uD83D\uDE4F', '\u2665', '\uD83D\uDC95', '\uD83D\uDC94',
    '\uD83D\uDE0D', '\uD83E\uDD23', '\uD83D\uDE2D', '\uD83E\uDD29',
    '\uD83D\uDE21', '\uD83D\uDE08', '\uD83D\uDC80', '\u2705',
    '\u274C', '\u2714', '\uD83C\uDF89', '\uD83D\uDCAF',
  ];

  // Avatar background colors
  static const List<int> avatarColors = [
    0xFF8B0000, 0xFF1565C0, 0xFF2E7D32, 0xFF6A1B9A,
    0xFF00838F, 0xFFEF6C00, 0xFFAD1457, 0xFF37474F,
    0xFF4E342E, 0xFF004D40, 0xFF1B5E20, 0xFF1A237E,
  ];

  // SharedPreferences keys
  static const String prefLanguage = 'lang';
  static const String prefTheme    = 'theme';
  static const String prefCurrentUser = 'cur_user';
  static const String prefAccounts = 'accounts';
  static const String prefChatBg   = 'chat_bg';

  // Private constructor
  AppConstants._();
}