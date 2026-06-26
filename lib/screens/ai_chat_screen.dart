import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/theme_notifier.dart';
import 'package:pyin_mal_app/models/ai_message.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/services/gemini_service.dart';
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
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _autoSend = true;
  String _currentLocaleId = 'my-MM';

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
    }
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
