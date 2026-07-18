// lib/screens/try_on_video_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../main.dart'; // AppColors
import '../services/fal_video_service.dart';

/// Turns a finished try-on image into a 360° turnaround video via fal.ai and
/// plays it. Generation takes ~1-3 minutes, so the screen shows the try-on
/// image with a progress overlay while it waits.
class TryOnVideoScreen extends StatefulWidget {
  /// Public URL of the generated try-on image (NanoBanana result).
  final String tryOnImageUrl;
  const TryOnVideoScreen({super.key, required this.tryOnImageUrl});

  @override
  State<TryOnVideoScreen> createState() => _TryOnVideoScreenState();
}

class _TryOnVideoScreenState extends State<TryOnVideoScreen> {
  FalVideoStatus _status = FalVideoStatus.submitting;
  String? _videoUrl;
  VideoPlayerController? _player;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _status = FalVideoStatus.submitting;
      _videoUrl = null;
    });
    final url = await FalVideoService.generateTurnaroundVideo(
      imageUrl: widget.tryOnImageUrl,
      onStatus: (s) {
        if (mounted) setState(() => _status = s);
      },
    );
    if (!mounted) return;
    if (url == null) {
      setState(() => _status = FalVideoStatus.failed);
      return;
    }
    final player = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await player.initialize();
    } catch (e) {
      debugPrint('❗ video init failed: $e');
      player.dispose();
      if (mounted) setState(() => _status = FalVideoStatus.failed);
      return;
    }
    if (!mounted) {
      player.dispose();
      return;
    }
    player
      ..setLooping(true)
      ..play();
    setState(() {
      _videoUrl = url;
      _player = player;
    });
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _accent => _isDark ? AppColors.gold : AppColors.burgundy;

  String get _statusText => switch (_status) {
        FalVideoStatus.submitting => 'Sending your look to the studio…',
        FalVideoStatus.queued => 'Waiting in line…',
        FalVideoStatus.generating => 'Creating your 360° view…\nThis takes 1-3 minutes',
        FalVideoStatus.done => '',
        FalVideoStatus.failed => 'Something went wrong',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_player != null)
              Center(
                child: AspectRatio(
                  aspectRatio: _player!.value.aspectRatio,
                  child: VideoPlayer(_player!),
                ),
              )
            else
              _buildWaiting(),
            _buildTopBar(),
            if (_status == FalVideoStatus.failed) _buildFailed(),
          ],
        ),
      ),
    );
  }

  /// The try-on image, dimmed, with live progress text — so the user is
  /// looking at their result (not a blank spinner) while the video renders.
  Widget _buildWaiting() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          widget.tryOnImageUrl,
          fit: BoxFit.contain,
          color: Colors.black.withOpacity(0.45),
          colorBlendMode: BlendMode.darken,
          errorBuilder: (_, __, ___) => const SizedBox.expand(),
        ),
        if (_status != FalVideoStatus.failed)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(color: _accent, strokeWidth: 3),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You can keep browsing and come back — but leaving this screen cancels the video.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildFailed() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white70, size: 44),
            const SizedBox(height: 12),
            Text('Video generation failed',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Check your connection and fal.ai credit, then try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Retry',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child:
                    const Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.threed_rotation_rounded, size: 15, color: _accent),
                  const SizedBox(width: 6),
                  Text('360° View',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            // Replay button (visible once the video is playing)
            if (_videoUrl != null)
              GestureDetector(
                onTap: () {
                  _player?.seekTo(Duration.zero);
                  _player?.play();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.replay_rounded,
                      color: Colors.white, size: 20),
                ),
              )
            else
              const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}
