import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';

/// "Events" quick-access — fashion pop-ups, launches and sales across
/// Yangon & Mandalay. Static demo content for now.
class _FashionEvent {
  final String title;
  final String host;
  final String date;
  final String location;
  final String tag;
  final Color color;
  final IconData icon;
  final String desc;
  final bool live;

  const _FashionEvent({
    required this.title,
    required this.host,
    required this.date,
    required this.location,
    required this.tag,
    required this.color,
    required this.icon,
    required this.desc,
    this.live = false,
  });
}

const _events = <_FashionEvent>[
  _FashionEvent(
    title: 'Seasonal Pop-Up Store',
    host: 'CLASSYDOCK',
    date: 'Now – 31 Jul',
    location: 'Junction City, Ground Floor · Yangon',
    tag: 'LIVE NOW',
    color: Color(0xFFB0293F),
    icon: Icons.storefront_rounded,
    desc:
        'Bold everyday fits and exclusive drops you won\'t find online. Swing by the ground-floor pop-up before it closes.',
    live: true,
  ),
  _FashionEvent(
    title: 'Flash Sale Weekend',
    host: 'NRF Store & Friends',
    date: 'Fri – Sun',
    location: 'App-wide · Up to 40% off',
    tag: 'SALE',
    color: Color(0xFFE05B4B),
    icon: Icons.local_fire_department_rounded,
    desc:
        'Three days of the deepest cuts of the season across streetwear, hoodies and tees. Countdown timers in the app.',
  ),
  _FashionEvent(
    title: 'New Collection Launch',
    host: 'Malory',
    date: '5 Aug · 6:00 PM',
    location: 'Myanmar Plaza · Yangon',
    tag: 'LAUNCH',
    color: Color(0xFF6A1B9A),
    icon: Icons.auto_awesome_rounded,
    desc:
        'Be the first to see the Anniversary line. Early access for app members, plus a styling corner on the night.',
  ),
  _FashionEvent(
    title: 'Sustainable Style Meetup',
    host: 'Pyin Mal Resell Community',
    date: '12 Aug · 2:00 PM',
    location: 'Sanchaung · Yangon',
    tag: 'COMMUNITY',
    color: Color(0xFF2E7D32),
    icon: Icons.recycling_rounded,
    desc:
        'Swap, resell and donate pre-loved fashion. Bring pieces you no longer wear and give them a second life.',
  ),
  _FashionEvent(
    title: 'Mandalay Fashion Night',
    host: 'Burmese Studio',
    date: '20 Aug · 7:00 PM',
    location: '78th Street · Mandalay',
    tag: 'SHOWCASE',
    color: Color(0xFFCB7A2B),
    icon: Icons.checkroom_rounded,
    desc:
        'Traditional meets modern in a one-night runway showcase. Limited seats — reserve through the app.',
  ),
];

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _pc = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;

  // Featured slides for the top carousel.
  List<_FashionEvent> get _featured => _events.take(3).toList();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pc.hasClients) return;
      final next = (_page + 1) % _featured.length;
      _pc.animateToPage(next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bg = isDark ? AppColors.charcoal : const Color(0xFFF5F2EE);
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: ink),
        title: Text('Events',
            style: GoogleFonts.rufina(
                fontWeight: FontWeight.bold, color: ink, fontSize: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text('Fashion happenings across Yangon & Mandalay',
                style: GoogleFonts.outfit(fontSize: 13, color: muted)),
          ),

          // ── Featured carousel ──
          SizedBox(
            height: 176,
            child: PageView.builder(
              controller: _pc,
              itemCount: _featured.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => _heroSlide(_featured[i]),
            ),
          ),
          const SizedBox(height: 12),
          // dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_featured.length, (i) {
              final sel = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: sel ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: sel ? accent : accent.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          // ── Section label ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              children: [
                Icon(Icons.event_rounded, size: 18, color: accent),
                const SizedBox(width: 8),
                Text('All events',
                    style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ink)),
              ],
            ),
          ),

          // ── Event list ──
          ..._events.map((e) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _eventCard(context, e, isDark, accent, ink, muted),
              )),
        ],
      ),
    );
  }

  // ── Carousel slide (promo-banner style) ─────────────────────────────────────
  Widget _heroSlide(_FashionEvent e) {
    return GestureDetector(
      onTap: () => _toast(context, 'Opening "${e.title}"'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [e.color, Color.lerp(e.color, Colors.black, 0.42)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: e.color.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // watermark icon
              Positioned(
                right: -18,
                bottom: -22,
                child: Icon(e.icon,
                    size: 150, color: Colors.white.withOpacity(0.10)),
              ),
              Positioned(
                top: -30,
                right: 40,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: e.live
                            ? Colors.white
                            : Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (e.live) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: e.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(e.tag,
                              style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: e.live ? e.color : Colors.white)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(e.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.rufina(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 12, color: Colors.white70),
                        const SizedBox(width: 5),
                        Text(e.date,
                            style: GoogleFonts.outfit(
                                fontSize: 12, color: Colors.white70)),
                        const SizedBox(width: 12),
                        const Icon(Icons.place_rounded,
                            size: 12, color: Colors.white70),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(e.host,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                  fontSize: 12, color: Colors.white70)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View details',
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: e.color)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              size: 13, color: e.color),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating, content: Text(msg)));
  }

  Widget _eventCard(BuildContext context, _FashionEvent e, bool isDark,
      Color accent, Color ink, Color muted) {
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored banner strip with icon + tag
          Container(
            height: 74,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [e.color, Color.lerp(e.color, Colors.black, 0.3)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(e.icon, color: Colors.white, size: 24),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: e.live
                          ? Colors.white
                          : Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (e.live) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: e.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(e.tag,
                            style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: e.live ? e.color : Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title,
                    style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ink)),
                const SizedBox(height: 2),
                Text('by ${e.host}',
                    style: GoogleFonts.outfit(fontSize: 12, color: accent)),
                const SizedBox(height: 10),
                _metaRow(Icons.calendar_today_rounded, e.date, muted),
                const SizedBox(height: 5),
                _metaRow(Icons.place_rounded, e.location, muted),
                const SizedBox(height: 10),
                Text(e.desc,
                    style: GoogleFonts.outfit(
                        fontSize: 12.5, height: 1.45, color: muted)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _toast(context, 'Reminder set for "${e.title}"'),
                        icon: const Icon(Icons.notifications_none_rounded,
                            size: 16),
                        label: Text('Remind me',
                            style: GoogleFonts.outfit(
                                fontSize: 12.5, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ink,
                          side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : const Color(0xFFCCCCCC)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _toast(context, 'You\'re going to "${e.title}"! 🎉'),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: Text('Interested',
                            style: GoogleFonts.outfit(
                                fontSize: 12.5, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: e.color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text, Color muted) {
    return Row(
      children: [
        Icon(icon, size: 13, color: muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: GoogleFonts.outfit(fontSize: 12, color: muted)),
        ),
      ],
    );
  }
}
