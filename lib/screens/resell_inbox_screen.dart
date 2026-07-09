import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/screens/resell_chat_screen.dart';

/// One buyer ↔ seller conversation about one listed item.
class ResellConversation {
  final String buyer;
  final String itemTitle;
  final String itemPrice;
  final String itemImageAsset;
  final String lastMessage;
  final Duration age;
  int unread;

  ResellConversation({
    required this.buyer,
    required this.itemTitle,
    required this.itemPrice,
    this.itemImageAsset = '',
    required this.lastMessage,
    required this.age,
    this.unread = 0,
  });
}

/// In-memory seller inbox — each interested buyer gets their own thread,
/// so replies never mix together in one crowded chat.
class ResellInboxStore {
  static final List<ResellConversation> conversations = [
    ResellConversation(
      buyer: 'Thida K.',
      itemTitle: 'NRF Deathwish Hoodie',
      itemPrice: '28,000 MMK',
      itemImageAsset:
          'pyin-mal-assets/assets/images/Male/Nrf/Hoodie/b_NRF Deathwish hoodie_p1.jpg',
      lastMessage: 'Is it still available? Can you do 25,000?',
      age: const Duration(minutes: 6),
      unread: 2,
    ),
    ResellConversation(
      buyer: 'Ko Zaw',
      itemTitle: 'NRF Deathwish Hoodie',
      itemPrice: '28,000 MMK',
      itemImageAsset:
          'pyin-mal-assets/assets/images/Male/Nrf/Hoodie/b_NRF Deathwish hoodie_p1.jpg',
      lastMessage: 'What are the exact measurements?',
      age: const Duration(minutes: 48),
      unread: 1,
    ),
    ResellConversation(
      buyer: 'Su Su',
      itemTitle: 'ABCD Tee',
      itemPrice: '8,000 MMK',
      itemImageAsset:
          'pyin-mal-assets/assets/images/Male/Nrf/Tee/b_ABCD TEE_p1.jpg',
      lastMessage: 'Great, see you at Junction City at 5!',
      age: const Duration(hours: 3),
    ),
    ResellConversation(
      buyer: 'Aung M.',
      itemTitle: 'ACID T-Shirt',
      itemPrice: '9,500 MMK',
      itemImageAsset:
          'pyin-mal-assets/assets/images/Male/Nrf/Tee/b_ACID TSHIRT_p1.jpg',
      lastMessage: 'You: Sure, it fits like a regular L.',
      age: const Duration(days: 1),
    ),
  ];

  static int get unreadCount =>
      conversations.fold(0, (sum, c) => sum + c.unread);
}

class ResellInboxScreen extends StatefulWidget {
  const ResellInboxScreen({super.key});

  @override
  State<ResellInboxScreen> createState() => _ResellInboxScreenState();
}

class _ResellInboxScreenState extends State<ResellInboxScreen> {
  String _ago(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bg = isDark ? AppColors.charcoal : const Color(0xFFF5F2EE);
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    // Group conversations by item so a seller sees interest per listing.
    final byItem = <String, List<ResellConversation>>{};
    for (final c in ResellInboxStore.conversations) {
      byItem.putIfAbsent(c.itemTitle, () => []).add(c);
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: ink),
        title: Text('Messages',
            style: GoogleFonts.rufina(
                fontWeight: FontWeight.bold, color: ink, fontSize: 22)),
      ),
      body: ResellInboxStore.conversations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 48, color: muted),
                  const SizedBox(height: 12),
                  Text('No messages yet',
                      style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ink)),
                  const SizedBox(height: 5),
                  Text('When buyers message your listings,\nchats appear here.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 12, color: muted)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                for (final entry in byItem.entries) ...[
                  // ── Item group header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
                    child: Row(
                      children: [
                        Icon(Icons.sell_rounded, size: 14, color: accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(entry.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: ink)),
                        ),
                        Text(
                            '${entry.value.length} interested buyer${entry.value.length == 1 ? '' : 's'}',
                            style: GoogleFonts.outfit(
                                fontSize: 11, color: muted)),
                      ],
                    ),
                  ),
                  // ── One thread per buyer ──
                  ...entry.value.map((c) => GestureDetector(
                        onTap: () async {
                          setState(() => c.unread = 0);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResellChatScreen(
                                seller: c.buyer,
                                itemTitle: c.itemTitle,
                                itemPrice: c.itemPrice,
                                itemImageAsset: c.itemImageAsset,
                              ),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: c.unread > 0
                                    ? accent.withOpacity(0.45)
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.creamAlt)),
                          ),
                          child: Row(
                            children: [
                              // Buyer avatar
                              CircleAvatar(
                                radius: 21,
                                backgroundColor: accent.withOpacity(0.15),
                                child: Text(c.buyer[0],
                                    style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: accent)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(c.buyer,
                                              style: GoogleFonts.outfit(
                                                  fontSize: 14,
                                                  fontWeight: c.unread > 0
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                  color: ink)),
                                        ),
                                        Text(_ago(c.age),
                                            style: GoogleFonts.outfit(
                                                fontSize: 11, color: muted)),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(c.lastMessage,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  fontWeight: c.unread > 0
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                  color: c.unread > 0
                                                      ? ink
                                                      : muted)),
                                        ),
                                        if (c.unread > 0)
                                          Container(
                                            margin: const EdgeInsets.only(
                                                left: 8),
                                            padding:
                                                const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              color: accent,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints:
                                                const BoxConstraints(
                                                    minWidth: 19,
                                                    minHeight: 19),
                                            child: Text('${c.unread}',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.outfit(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    color: isDark
                                                        ? AppColors.charcoal
                                                        : Colors.white)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ],
            ),
    );
  }
}
