import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/theme_notifier.dart';
import 'package:pyin_mal_app/models/ai_message.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/services/gemini_service.dart';
import 'package:pyin_mal_app/services/database_service.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/screens/product_detail_screen.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  final DatabaseService _db = DatabaseService();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _autoSend = true;
  String _currentLocaleId = 'my-MM';

  // Firestore id of the conversation currently open. Null until the first user
  // message is sent (a fresh, unsaved chat).
  String? _conversationId;

  final List<AiMessage> _messages = [
    AiMessage(
      text: 'ai_chat.greeting'.tr(),
      isUser: false,
    ),
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
          if (_autoSend && _textController.text.trim().isNotEmpty) {
            _sendMessage();
          }
        }
      },
      onError: (errorNotification) {
        setState(() {
          _isListening = false;
        });
      },
    );
    setState(() {});
  }

  void _startListening() async {
    FocusScope.of(context).unfocus(); // Unfocus keyboard
    _textController.clear();
    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _textController.text = result.recognizedWords;
        });
      },
      localeId: _currentLocaleId,
    );
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    // Start a new conversation id on the first user message.
    _conversationId ??= DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      _messages.add(AiMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    final response = await _geminiService.sendMessage(text);

    if (mounted) {
      setState(() {
        _messages.add(response);
        _isLoading = false;
      });
      _scrollToBottom();
      _persistConversation();
    }
  }

  /// Save the current conversation (best-effort). Title is the first user turn.
  void _persistConversation() {
    final id = _conversationId;
    if (id == null) return;
    final firstUser = _messages.firstWhere(
      (m) => m.isUser,
      orElse: () => AiMessage(text: 'New chat', isUser: true),
    );
    var title = firstUser.text.trim();
    if (title.length > 60) title = '${title.substring(0, 60)}…';
    _db
        .saveAiConversation(
          id: id,
          title: title.isEmpty ? 'New chat' : title,
          messages: _messages.map((m) => m.toMap()).toList(),
        )
        .catchError((e) => debugPrint('Save conversation failed: $e'));
  }

  /// Reset to a fresh, empty chat.
  void _startNewChat() {
    _geminiService.reset();
    setState(() {
      _conversationId = null;
      _messages
        ..clear()
        ..add(AiMessage(text: 'ai_chat.greeting'.tr(), isUser: false));
    });
  }

  /// Load a saved conversation into the screen and restore the AI's context.
  Future<void> _openConversation(Map<String, dynamic> convo) async {
    await ProductRepository.load();
    final rawMessages = (convo['messages'] as List?) ?? [];
    final restored = <AiMessage>[];
    for (final m in rawMessages) {
      final map = Map<String, dynamic>.from(m as Map);
      final ids = (map['productIds'] as List?) ?? [];
      final products = <Product>[];
      for (final id in ids) {
        final p = ProductRepository.getProductById(id.toString());
        if (p != null) products.add(p);
      }
      restored.add(AiMessage(
        text: map['text'] as String? ?? '',
        isUser: map['isUser'] as bool? ?? false,
        recommendedProducts: products,
      ));
    }
    _geminiService.seedHistory(restored);
    setState(() {
      _conversationId = convo['id'] as String?;
      _messages
        ..clear()
        ..addAll(restored.isEmpty
            ? [AiMessage(text: 'ai_chat.greeting'.tr(), isUser: false)]
            : restored);
    });
    _scrollToBottom();
  }

  void _showHistorySheet(bool isDark, Color accent) {
    final sheetBg = isDark ? AppColors.charcoal : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetCtx).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: muted.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text('Chat history',
                          style: GoogleFonts.rufina(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ink)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _startNewChat();
                        },
                        icon: Icon(Icons.add_rounded, size: 18, color: accent),
                        label: Text('New',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700, color: accent)),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _db.streamAiConversations(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                              child: CircularProgressIndicator(color: accent)),
                        );
                      }
                      final convos = snap.data ?? [];
                      if (convos.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text('No saved conversations yet.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(color: muted)),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        itemCount: convos.length,
                        separatorBuilder: (_, __) => Divider(
                            height: 1, color: muted.withOpacity(0.12)),
                        itemBuilder: (context, i) {
                          final c = convos[i];
                          final id = c['id'] as String?;
                          final isCurrent = id == _conversationId;
                          final count = (c['messages'] as List?)?.length ?? 0;
                          return ListTile(
                            leading: Icon(Icons.chat_bubble_outline_rounded,
                                color: accent, size: 22),
                            title: Text(
                              c['title'] as String? ?? 'Chat',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ink),
                            ),
                            subtitle: Text('$count messages',
                                style: GoogleFonts.outfit(
                                    fontSize: 12, color: muted)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('Current',
                                        style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: accent)),
                                  ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded,
                                      size: 20, color: muted),
                                  onPressed: () async {
                                    if (id == null) return;
                                    await _db.deleteAiConversation(id);
                                    if (isCurrent) {
                                      Navigator.pop(sheetCtx);
                                      _startNewChat();
                                    }
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              _openConversation(c);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bgColor = isDark ? AppColors.charcoal : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.inkBlack,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ai_chat.title'.tr(),
          style: GoogleFonts.rufina(
            color: isDark ? Colors.white : AppColors.inkBlack,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Chat history',
            icon: Icon(Icons.history_rounded,
                color: isDark ? Colors.white : AppColors.inkBlack),
            onPressed: () => _showHistorySheet(isDark, accent),
          ),
          IconButton(
            tooltip: 'New chat',
            icon: Icon(Icons.add_comment_outlined,
                color: isDark ? Colors.white : AppColors.inkBlack),
            onPressed: _startNewChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator(isDark, accent);
                }
                return _buildMessageBubble(_messages[index], isDark, accent);
              },
            ),
          ),
          // Input Area
          _buildInputArea(isDark, accent),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark, Color accent) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
          borderRadius: BorderRadius.circular(20).copyWith(bottomLeft: Radius.zero),
        ),
        child: SizedBox(
          width: 40,
          height: 20,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AiMessage message, bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Text Bubble
          Align(
            alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? accent
                    : (isDark ? AppColors.darkWarm : AppColors.creamAlt),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: message.isUser ? Radius.zero : const Radius.circular(20),
                  bottomLeft: message.isUser ? const Radius.circular(20) : Radius.zero,
                ),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: message.isUser
                      ? (isDark ? AppColors.charcoal : Colors.white)
                      : (isDark ? Colors.white : AppColors.inkBlack),
                ),
              ),
            ),
          ),
          // Recommended Products
          if (message.recommendedProducts.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: message.recommendedProducts.length,
                itemBuilder: (context, index) {
                  return _buildRecommendedProductCard(message.recommendedProducts[index], isDark, accent);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendedProductCard(Product product, bool isDark, Color accent) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen.fromProduct(product),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.charcoal.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CdnImage(
                  product.image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.inkBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.price,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark, Color accent) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.charcoal : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Column(
        children: [
          if (_speechEnabled)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Auto-send', style: GoogleFonts.outfit(color: isDark ? Colors.white70 : AppColors.inkGrey, fontSize: 12)),
                      Switch(
                        value: _autoSend,
                        onChanged: (val) => setState(() => _autoSend = val),
                        activeColor: accent,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _currentLocaleId = 'en-US'),
                        child: Text('EN', style: GoogleFonts.outfit(color: _currentLocaleId == 'en-US' ? accent : (isDark ? Colors.white70 : AppColors.inkGrey), fontSize: 12, fontWeight: _currentLocaleId == 'en-US' ? FontWeight.bold : FontWeight.normal)),
                      ),
                      const SizedBox(width: 8),
                      Text('|', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _currentLocaleId = 'my-MM'),
                        child: Text('MM', style: GoogleFonts.outfit(color: _currentLocaleId == 'my-MM' ? accent : (isDark ? Colors.white70 : AppColors.inkGrey), fontSize: 12, fontWeight: _currentLocaleId == 'my-MM' ? FontWeight.bold : FontWeight.normal)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _textController,
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white : AppColors.inkBlack,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ai_chat.ask_advice'.tr(),
                      hintStyle: GoogleFonts.outfit(
                        color: isDark ? AppColors.paleText : AppColors.inkGrey,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_speechEnabled)
                GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.red : (isDark ? AppColors.darkWarm : AppColors.creamAlt),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.white : (isDark ? Colors.white : AppColors.inkBlack),
                      size: 24,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: isDark ? AppColors.charcoal : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
