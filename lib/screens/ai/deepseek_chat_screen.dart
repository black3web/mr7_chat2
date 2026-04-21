import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ai_service.dart';
import '../../widgets/ai_chat_widgets.dart';

class DeepSeekChatScreen extends StatefulWidget {
  const DeepSeekChatScreen({super.key});
  @override
  State<DeepSeekChatScreen> createState() => _DeepSeekChatScreenState();
}

class _DeepSeekChatScreenState extends State<DeepSeekChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<AiMessage> _messages = [];
  bool _loading = false;
  String _model = '1';
  String? _conversationId;

  static const _modelNames = {
    '1': 'DeepSeek V3.2',
    '2': 'DeepSeek R1',
    '3': 'DeepSeek Coder',
  };

  @override
  void initState() {
    super.initState();
    _addBot('مرحباً! اختر النموذج المناسب ثم اسألني ما تريد. 🤖');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _addBot(String text, {bool isError = false}) {
    _messages.insert(0, AiMessage(text: text, isUser: false, time: DateTime.now(), isError: isError));
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    final userId = context.read<AppProvider>().currentUser?.id ?? '';
    _ctrl.clear();
    setState(() {
      _messages.insert(0, AiMessage(text: text, isUser: true, time: DateTime.now()));
      _loading = true;
    });
    try {
      final result = await AiService().deepSeekChat(
        text, userId,
        model: _model,
        conversationId: _conversationId,
      );
      _conversationId = result['conversation_id'] as String?;
      if (mounted) {
        setState(() => _addBot(result['response'] as String));
      }
    } catch (e) {
      if (mounted) {
        final errMsg = e.toString().replaceAll('Exception: ', '');
        setState(() => _addBot(errMsg.isNotEmpty ? errMsg : 'حدث خطأ. حاول مجدداً.', isError: true));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeModel(String key) {
    setState(() {
      _model = key;
      _conversationId = null; // Reset conversation when changing model
      _messages.clear();
      _addBot('تم التبديل إلى ${_modelNames[key]}. كيف يمكنني مساعدتك؟');
    });
  }

  void _clearHistory() {
    setState(() {
      _conversationId = null;
      _messages.clear();
      _addBot('تم مسح المحادثة. كيف يمكنني مساعدتك؟');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l  = AppLocalizations.of(context);
    final me = context.read<AppProvider>().currentUser;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.backgroundGradient),
        child: SafeArea(
          child: Column(children: [
            AiScreenHeader(
              title: _modelNames[_model] ?? 'DeepSeek',
              subtitle: 'DeepSeek AI',
              color: const Color(0xFF00BCD4),
              icon: Icons.psychology_rounded,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.textSecondary),
                  tooltip: 'تغيير النموذج',
                  itemBuilder: (_) => _modelNames.entries.map((e) => PopupMenuItem(
                    value: e.key,
                    child: Row(children: [
                      if (_model == e.key) const Icon(Icons.check, size: 16, color: AppColors.accent),
                      if (_model == e.key) const SizedBox(width: 6),
                      Text(e.value),
                    ]),
                  )).toList(),
                  onSelected: _changeModel,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.textMuted, size: 20),
                  onPressed: _clearHistory,
                  tooltip: 'مسح المحادثة',
                ),
              ],
            ),
            // Model selector chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: _modelNames.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _changeModel(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: _model == e.key ? const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF0097A7)]) : null,
                        color: _model == e.key ? null : AppColors.bgLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _model == e.key ? const Color(0xFF00BCD4) : AppColors.glassBorder,
                        ),
                      ),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          color: _model == e.key ? Colors.white : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: _model == e.key ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (_loading && i == 0) return const AiTypingIndicator();
                  final msg = _messages[_loading ? i - 1 : i];
                  return AiMessageBubble(msg: msg, userPhotoUrl: me?.photoUrl, userName: me?.name ?? '?');
                },
              ),
            ),
            AiInputBar(ctrl: _ctrl, onSend: _send, loading: _loading, hint: l['sendPrompt']),
          ]),
        ),
      ),
    );
  }
}
