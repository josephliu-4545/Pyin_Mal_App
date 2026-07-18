import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/services/floating_scanner_service.dart';

/// Full-screen permission onboarding for the floating scanner.
/// Guides the user through all required permissions, including
/// MIUI-specific steps for Xiaomi devices.
class OverlayPermissionScreen extends StatefulWidget {
  const OverlayPermissionScreen({super.key});

  @override
  State<OverlayPermissionScreen> createState() =>
      _OverlayPermissionScreenState();
}

class _OverlayPermissionScreenState extends State<OverlayPermissionScreen>
    with WidgetsBindingObserver {
  bool _overlayGranted      = false;
  bool _batteryGranted      = false;
  bool _notificationGranted = false;
  bool _checking            = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check permissions when the user comes back from Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final overlayResult = await FlutterOverlayWindow.isPermissionGranted();
    final overlay      = overlayResult == true;
    final battery      = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    final notifStatus  = await FlutterForegroundTask.checkNotificationPermission();
    final notif        = notifStatus == NotificationPermission.granted;
    if (mounted) setState(() {
      _overlayGranted      = overlay;
      _batteryGranted      = battery;
      _notificationGranted = notif;
    });
  }

  bool get _allGranted => _overlayGranted && _batteryGranted && _notificationGranted;

  Future<void> _requestOverlay() async {
    await FlutterOverlayWindow.requestPermission();
    await _refreshStatus();
  }

  Future<void> _requestBattery() async {
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    await _refreshStatus();
  }

  Future<void> _requestNotification() async {
    await FlutterForegroundTask.requestNotificationPermission();
    await _refreshStatus();
  }

  Future<void> _activateScanner() async {
    setState(() => _checking = true);
    final ok = await FloatingScannerService.enable();
    if (mounted) {
      setState(() => _checking = false);
      if (ok) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not start scanner. Check permissions.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return Scaffold(
      appBar: AppBar(
        title: Text('Floating Scanner Setup',
            style: GoogleFonts.rufina(fontWeight: FontWeight.bold)),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Header
            Text('Enable Floating Scanner',
                style: GoogleFonts.rufina(
                    fontSize: 24, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.inkBlack)),
            const SizedBox(height: 8),
            Text(
              'The scanner floats over any app so you can scan clothing '
              'without switching back to Ta Chat Nhate.',
              style: GoogleFonts.outfit(fontSize: 14,
                  color: isDark ? AppColors.paleText : AppColors.inkGrey),
            ),
            const SizedBox(height: 32),

            // ── Permission 1: Overlay ─────────────────────────────────────
            _PermissionTile(
              icon:    Icons.layers_rounded,
              title:   'Draw over other apps',
              desc:    'Required to show the floating button above other apps.',
              granted: _overlayGranted,
              accent:  accent,
              onTap:   _overlayGranted ? null : _requestOverlay,
            ),
            const SizedBox(height: 16),

            // ── Permission 2: Battery ─────────────────────────────────────
            _PermissionTile(
              icon:    Icons.battery_charging_full_rounded,
              title:   'Ignore battery optimizations',
              desc:    'Keeps the scanner alive when the app is in background.',
              granted: _batteryGranted,
              accent:  accent,
              onTap:   _batteryGranted ? null : _requestBattery,
            ),
            const SizedBox(height: 16),

            // ── Permission 3: Notifications (Android 13+) ─────────────────
            _PermissionTile(
              icon:    Icons.notifications_outlined,
              title:   'Show notifications',
              desc:    'Required on Android 13+ to keep the scanner running.',
              granted: _notificationGranted,
              accent:  accent,
              onTap:   _notificationGranted ? null : _requestNotification,
            ),
            const SizedBox(height: 28),

            // ── MIUI extra steps ──────────────────────────────────────────
            _MiuiGuideCard(accent: accent),
            const SizedBox(height: 32),

            // ── Activate button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _allGranted && !_checking ? _activateScanner : null,
                child: _checking
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_allGranted
                        ? 'Activate Floating Scanner'
                        : 'Grant permissions above first'),
              ),
            ),
            const SizedBox(height: 16),

            // Fine print
            Text(
              'Android requires a persistent notification while the scanner '
              'is active. You will see "ta chat nhate Scanner is active" in '
              'your notification shade.',
              style: GoogleFonts.outfit(fontSize: 12,
                  color: isDark ? AppColors.paleText : AppColors.inkGrey),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Permission tile ───────────────────────────────────────────────────────────
class _PermissionTile extends StatelessWidget {
  final IconData icon; final String title, desc;
  final bool granted; final Color accent;
  final VoidCallback? onTap;
  const _PermissionTile({required this.icon, required this.title,
      required this.desc, required this.granted, required this.accent,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkWarm : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: (granted ? Colors.green : accent).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(granted ? Icons.check_rounded : icon,
                  color: granted ? Colors.green : accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(title, style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 14,
                  color: isDark ? Colors.white : AppColors.inkBlack)),
              Text(desc, style: GoogleFonts.outfit(fontSize: 12,
                  color: isDark ? AppColors.paleText : AppColors.inkGrey)),
            ])),
            if (!granted)
              Icon(Icons.arrow_forward_ios_rounded, size: 14,
                  color: isDark ? AppColors.paleText : AppColors.inkGrey),
          ]),
        ),
      ),
    );
  }
}

// ── MIUI-specific guide ───────────────────────────────────────────────────────
class _MiuiGuideCard extends StatelessWidget {
  final Color accent;
  const _MiuiGuideCard({required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.phone_android_rounded, color: accent, size: 20),
          const SizedBox(width: 8),
          Text('Xiaomi / MIUI extra steps',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
                  fontSize: 14, color: isDark ? Colors.white : AppColors.inkBlack)),
        ]),
        const SizedBox(height: 10),
        _MiuiStep(n: '1', text:
            'Settings → Apps → Manage apps → Ta Chat Nhate → Other permissions\n'
            '→ Enable "Display pop-up window"'),
        const SizedBox(height: 8),
        _MiuiStep(n: '2', text:
            'Same page → Enable "Start in background"'),
        const SizedBox(height: 8),
        _MiuiStep(n: '3', text:
            'Settings → Apps → Manage apps → Ta Chat Nhate\n'
            '→ Battery saver → No restrictions'),
      ]),
    );
  }
}

class _MiuiStep extends StatelessWidget {
  final String n, text;
  const _MiuiStep({required this.n, required this.text});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 20, height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: AppColors.gold.withOpacity(0.3)),
          child: Text(n, style: GoogleFonts.outfit(fontSize: 11,
              fontWeight: FontWeight.bold, color: AppColors.gold))),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: GoogleFonts.outfit(fontSize: 12,
          color: isDark ? AppColors.paleText : AppColors.inkGrey))),
    ]);
  }
}
