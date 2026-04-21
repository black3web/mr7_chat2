import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/language_select_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/chat/group_chat_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/stories/story_view_screen.dart';
import '../screens/stories/add_story_screen.dart';
import '../screens/ai/gemini_chat_screen.dart';
import '../screens/ai/deepseek_chat_screen.dart';
import '../screens/ai/image_gen_screen.dart';
import '../screens/ai/video_gen_screen.dart';
import '../screens/ai/music_ai_screen.dart';
import '../screens/ai/kilwa_video_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/support/support_screen.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/search/search_screen.dart';
import '../models/story_model.dart';

class AppRoutes {
  // Static route names
  static const String splash       = '/';
  static const String language     = '/language';
  static const String login        = '/login';
  static const String register     = '/register';
  static const String home         = '/home';
  static const String chat         = '/chat';
  static const String groupChat    = '/group-chat';
  static const String profile      = '/profile';
  static const String editProfile  = '/edit-profile';
  static const String userProfile  = '/user-profile';
  static const String storyView    = '/story-view';
  static const String addStory     = '/add-story';
  static const String geminiChat   = '/ai/gemini';
  static const String deepSeekChat = '/ai/deepseek';
  static const String imageGen     = '/ai/image-gen';
  static const String imageGenPro  = '/ai/image-gen-pro';
  static const String videoGen     = '/ai/video-gen';
  static const String musicAi      = '/ai/music';
  static const String kilwaVideo   = '/ai/kilwa-video';
  static const String settings     = '/settings';
  static const String support      = '/support';
  static const String admin        = '/admin';
  static const String search       = '/search';

  // Named routes for simple navigation
  static Map<String, WidgetBuilder> get routes => {
    splash:      (_) => const SplashScreen(),
    language:    (_) => const LanguageSelectScreen(),
    login:       (_) => const LoginScreen(),
    register:    (_) => const RegisterScreen(),
    home:        (_) => const HomeScreen(),
    profile:     (_) => const ProfileScreen(),
    editProfile: (_) => const EditProfileScreen(),
    settings:    (_) => const SettingsScreen(),
    support:     (_) => const SupportScreen(),
    admin:       (_) => const AdminScreen(),
    search:      (_) => const SearchScreen(),
    geminiChat:  (_) => const GeminiChatScreen(),
    deepSeekChat:(_) => const DeepSeekChatScreen(),
    imageGen:    (_) => const ImageGenScreen(),
    imageGenPro: (_) => const ImageGenScreen(),
    videoGen:    (_) => const VideoGenScreen(),
    musicAi:     (_) => const MusicAiScreen(),
    kilwaVideo:  (_) => const KilwaVideoScreen(),
    addStory:    (_) => const AddStoryScreen(),
  };

  // Generated routes for routes with arguments
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case chat:
        final args = settings.arguments as Map<String, dynamic>;
        return _slide(
          ChatScreen(
            chatId: args['chatId'] as String,
            otherUserId: args['otherUserId'] as String,
          ),
        );
      case groupChat:
        final args = settings.arguments as Map<String, dynamic>;
        return _slide(GroupChatScreen(groupId: args['groupId'] as String));
      case userProfile:
        final args = settings.arguments as Map<String, dynamic>;
        return _slide(UserProfileScreen(userId: args['userId'] as String));
      case storyView:
        final args = settings.arguments as Map<String, dynamic>;
        return _fade(StoryViewScreen(
          stories: (args['stories'] as List).cast<StoryModel>(),
          initialIndex: (args['initialIndex'] as int?) ?? 0,
        ));
      default:
        return _slide(const SplashScreen());
    }
  }

  static PageRouteBuilder<T> _slide<T>(Widget child) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, animation, __) => child,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
    );
  }

  static PageRouteBuilder<T> _fade<T>(Widget child) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, animation, __) => child,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 220),
    );
  }
}