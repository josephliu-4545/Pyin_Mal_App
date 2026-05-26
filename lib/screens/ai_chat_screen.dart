import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/theme_notifier.dart';
import 'package:pyin_mal_app/models/ai_message.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/services/gemini_service.dart';
import 'package:pyin_mal_app/screens/product_detail_screen.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();

  final List<AiMessage> _messages = [
    AiMessage(
      text: "Hi! I'm your Pyin Mal Stylist ✨\nI can help you find the perfect outfit or suggest a great haircut. What are you looking for today?",
      isUser: false,
    ),
  ];
  
  bool _isLoading = false;

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
          'AI Stylist',
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
            builder: (_) => ProductDetailScreen(
              name: product.name,
              price: product.price,
              image: product.image,
              brand: product.brand,
              category: product.category,
            ),
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
      child: Row(
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
                  hintText: 'Ask for advice...',
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
          const SizedBox(width: 12),
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
    );
  }
}
