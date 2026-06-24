import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';

class _ChatMessage {
  final String text;
  final bool fromMe;
  final DateTime time;
  _ChatMessage(this.text, this.fromMe) : time = DateTime.now();
}

/// Simple in-memory chat between buyer and reseller about an item.
class ResellChatScreen extends StatefulWidget {
  final String seller;
  final String itemTitle;
  final String itemPrice;
  final String? itemImageAsset;
  final Uint8List? itemImageBytes;

  const ResellChatScreen({
    super.key,
    required this.seller,
    required this.itemTitle,
    required this.itemPrice,
    this.itemImageAsset,
    this.itemImageBytes,
  });

  @override
  State<ResellChatScreen> createState() => _ResellChatScreenState();
}

class _ResellChatScreenState extends State<ResellChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  late final List<_ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    // Seed with a greeting from the seller.
    _messages = [
      _ChatMessage(
          'Hi! Thanks for your interest in "${widget.itemTitle}". Happy to answer any questions 😊',
          false),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text, true));
      _controller.clear();
    });
    _scrollToEnd();
    // Simulate a seller reply.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage(
          'Sure! It\'s in great condition and still available. Let me know if you\'d like to meet up.',
          false)));
      _scrollToEnd();
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bg = isDark ? AppColors.charcoal : const Color(0xFFF5F2EE);
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
              decoration: BoxDecoration(
                color: cardBg,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.arrow_back_ios_rounded,
                          size: 20, color: ink),
                    ),
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: accent.withOpacity(0.15),
                    child: Text(widget.seller[0],
                        style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: accent)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.seller,
                            style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: ink)),
                        Text('Usually replies within an hour',
                            style:
                                GoogleFonts.outfit(fontSize: 11, color: muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Item context bar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: widget.itemImageBytes != null
                          ? Image.memory(widget.itemImageBytes!,
                              fit: BoxFit.cover)
                          : CdnImage(widget.itemImageAsset ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.creamAlt)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.itemTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ink)),
                        Text(widget.itemPrice,
                            style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: accent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final m = _messages[i];
                  return Align(
                    alignment:
                        m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.72),
                      decoration: BoxDecoration(
                        color: m.fromMe ? accent : cardBg,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(m.fromMe ? 16 : 4),
                          bottomRight: Radius.circular(m.fromMe ? 4 : 16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.text,
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: m.fromMe
                                      ? (isDark
                                          ? AppColors.charcoal
                                          : Colors.white)
                                      : ink)),
                          const SizedBox(height: 3),
                          Text('${_two(m.time.hour)}:${_two(m.time.minute)}',
                              style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  color: m.fromMe
                                      ? (isDark
                                          ? AppColors.charcoal
                                              .withOpacity(0.6)
                                          : Colors.white70)
                                      : muted)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Composer
            Container(
              padding: EdgeInsets.fromLTRB(
                  12, 10, 12, 10 + MediaQuery.of(context).viewInsets.bottom),
              decoration: BoxDecoration(
                color: cardBg,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      style: GoogleFonts.outfit(fontSize: 14, color: ink),
                      decoration: InputDecoration(
                        hintText: 'Message ${widget.seller}...',
                        hintStyle: GoogleFonts.outfit(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFFAAAAAA)),
                        filled: true,
                        fillColor:
                            isDark ? Colors.white10 : const Color(0xFFF4F4F4),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.send_rounded,
                          color: isDark ? AppColors.charcoal : Colors.white,
                          size: 20),
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
}
