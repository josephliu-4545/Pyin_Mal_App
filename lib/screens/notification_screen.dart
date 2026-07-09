import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/screens/sale_screen.dart';
import 'package:pyin_mal_app/screens/resell_screen.dart';
import 'package:pyin_mal_app/screens/donate_screen.dart';
import 'package:pyin_mal_app/screens/delivery_screen.dart';

/// Notification kinds — used for the filter tabs, icon and colour.
enum NotifKind { shop, resell, donate, order }

class AppNotification {
  final NotifKind kind;
  final IconData icon;
  final String title;
  final String body;
  final Duration age; // how long ago
  bool read;
  /// Optional screen to open on tap.
  final WidgetBuilder? open;

  AppNotification({
    required this.kind,
    required this.icon,
    required this.title,
    required this.body,
    required this.age,
    this.read = false,
    this.open,
  });
}

/// In-memory store so read state persists during the session and other
/// features (e.g. resell) can push notifications later.
class NotificationStore {
  static final List<AppNotification> items = [
    // Resell — reactions & messages on the user's posts
    AppNotification(
      kind: NotifKind.resell,
      icon: Icons.chat_bubble_rounded,
      title: 'New message on your listing',
      body:
          'Thida K. asked about "NRF Deathwish Hoodie" — "Is it still available?"',
      age: const Duration(minutes: 8),
      open: (_) => const ResellScreen(),
    ),
    AppNotification(
      kind: NotifKind.resell,
      icon: Icons.favorite_rounded,
      title: 'Your listing is getting attention',
      body: '3 people liked "NRF Deathwish Hoodie" in the last hour.',
      age: const Duration(minutes: 42),
      open: (_) => const ResellScreen(),
    ),
    AppNotification(
      kind: NotifKind.order,
      icon: Icons.local_shipping_rounded,
      title: 'Your order is on the way',
      body: 'Order #PM2048 has been picked up and is heading to you.',
      age: const Duration(hours: 2),
      open: (_) => const DeliveryScreen(),
    ),
    AppNotification(
      kind: NotifKind.shop,
      icon: Icons.local_fire_department_rounded,
      title: 'Flash Sale is live!',
      body: 'Up to 40% off from NRF Store and CLASSYDOCK — ends tonight.',
      age: const Duration(hours: 5),
      open: (_) => const SaleScreen(),
    ),
    AppNotification(
      kind: NotifKind.shop,
      icon: Icons.new_releases_rounded,
      title: 'New drop from CLASSYDOCK',
      body: 'Star Wear collection just landed. Be the first to try it on.',
      age: const Duration(hours: 9),
    ),
    AppNotification(
      kind: NotifKind.resell,
      icon: Icons.sell_rounded,
      title: 'Your item sold!',
      body: '"ABCD Zip Up Hoodie" was bought by Ko Zaw. Arrange the pickup now.',
      age: const Duration(days: 1),
      read: true,
      open: (_) => const ResellScreen(),
    ),
    AppNotification(
      kind: NotifKind.donate,
      icon: Icons.volunteer_activism_rounded,
      title: 'Donation pickup confirmed',
      body:
          'Hninzigon Home for the Aged will receive your clothes tomorrow. +200 pts',
      age: const Duration(days: 1, hours: 6),
      read: true,
      open: (_) => const DonateScreen(),
    ),
    AppNotification(
      kind: NotifKind.shop,
      icon: Icons.stars_rounded,
      title: 'You earned reward points',
      body: '+640 pts from your last purchase. Keep styling!',
      age: const Duration(days: 2),
      read: true,
    ),
  ];

  static int get unreadCount => items.where((n) => !n.read).length;
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotifKind? _filter; // null = all

  Color _kindColor(NotifKind k) {
    switch (k) {
      case NotifKind.shop:
        return const Color(0xFFE05B4B);
      case NotifKind.resell:
        return const Color(0xFFCB7A2B);
      case NotifKind.donate:
        return const Color(0xFF52B788);
      case NotifKind.order:
        return const Color(0xFF3D9BE9);
    }
  }

  String _ago(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} hr ago';
    return '${d.inDays} d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bg = isDark ? AppColors.charcoal : const Color(0xFFF5F2EE);
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    final visible = _filter == null
        ? NotificationStore.items
        : NotificationStore.items.where((n) => n.kind == _filter).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: ink),
        title: Text('Notifications',
            style: GoogleFonts.rufina(
                fontWeight: FontWeight.bold, color: ink, fontSize: 22)),
        actions: [
          if (NotificationStore.unreadCount > 0)
            TextButton(
              onPressed: () => setState(() {
                for (final n in NotificationStore.items) {
                  n.read = true;
                }
              }),
              child: Text('Mark all read',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accent)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter chips ──
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip(null, 'All', accent, ink, isDark),
                _chip(NotifKind.shop, 'Shop', accent, ink, isDark),
                _chip(NotifKind.resell, 'Resell', accent, ink, isDark),
                _chip(NotifKind.donate, 'Donate', accent, ink, isDark),
                _chip(NotifKind.order, 'Orders', accent, ink, isDark),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 48, color: muted),
                        const SizedBox(height: 12),
                        Text('No notifications here yet',
                            style: GoogleFonts.outfit(
                                fontSize: 13, color: muted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    itemCount: visible.length,
                    itemBuilder: (_, i) {
                      final n = visible[i];
                      final c = _kindColor(n.kind);
                      return GestureDetector(
                        onTap: () {
                          setState(() => n.read = true);
                          if (n.open != null) {
                            Navigator.push(context,
                                MaterialPageRoute(builder: n.open!));
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: n.read
                                    ? (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.creamAlt)
                                    : accent.withOpacity(0.45)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: c.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(n.icon, size: 21, color: c),
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
                                          child: Text(n.title,
                                              style: GoogleFonts.outfit(
                                                  fontSize: 13.5,
                                                  fontWeight: n.read
                                                      ? FontWeight.w600
                                                      : FontWeight.w800,
                                                  color: ink)),
                                        ),
                                        if (!n.read)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: accent,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(n.body,
                                        style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            height: 1.35,
                                            color: muted)),
                                    const SizedBox(height: 5),
                                    Text(_ago(n.age),
                                        style: GoogleFonts.outfit(
                                            fontSize: 10.5, color: muted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
      NotifKind? kind, String label, Color accent, Color ink, bool isDark) {
    final sel = _filter == kind;
    return GestureDetector(
      onTap: () => setState(() => _filter = kind),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel
              ? accent
              : (isDark ? AppColors.darkWarm : Colors.white),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: sel
                    ? (isDark ? AppColors.charcoal : Colors.white)
                    : ink)),
      ),
    );
  }
}
