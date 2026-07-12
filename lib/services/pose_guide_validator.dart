import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:pyin_mal_app/services/pose_detection_service.dart';

/// Which Bodygram photo the user is currently taking.
enum BodyShot { front, side }

/// Result of checking a live [PoseResult] against Bodygram's pose requirements.
/// [ok] gates the auto-countdown; [hintKey] is an i18n key describing the one
/// most important thing to fix.
class PoseCheck {
  final bool ok;
  final String hintKey;
  const PoseCheck(this.ok, this.hintKey);
}

/// Turns live pose landmarks into a "are you posed correctly yet?" verdict.
///
/// All coordinates are normalized 0..1 (x left→right, y top→bottom) exactly as
/// [PoseDetectionService] emits them (already mirrored for the front camera).
///
/// Thresholds are deliberately named constants — they need tuning on a real
/// device, so [check] logs the computed metrics when [debug] is on.
class PoseGuideValidator {
  static bool debug = true;

  // Confidence below which a landmark is treated as "not seen".
  static const _minLikelihood = 0.5;

  // Full-body framing: head must sit in the upper band, feet near the bottom.
  static const _headMaxY = 0.28; // nose no lower than this
  static const _feetMinY = 0.78; // ankles no higher than this
  static const _edgeMargin = 0.02; // keep everything off the very edges

  // Front pose: shoulders must be clearly apart (not a profile).
  static const _frontMinShoulderDx = 0.14;
  // Front A-pose arm angle from vertical, in degrees.
  static const _armMinAngleDeg = 12.0;
  static const _armMaxAngleDeg = 55.0;

  // Side pose: shoulders collapse together when in true profile.
  static const _sideMaxShoulderDx = 0.11;
  // Side pose: wrists should stay close to the torso (arms down at sides).
  static const _sideMaxArmSpread = 0.16;

  static PoseCheck check(PoseResult? p, BodyShot shot) {
    if (p == null) return const PoseCheck(false, 'capture.hint_no_body');

    final lm = <String, ARLandmark?>{
      'nose': p.nose,
      'lSh': p.leftShoulder, 'rSh': p.rightShoulder,
      'lWr': p.leftWrist, 'rWr': p.rightWrist,
      'lHip': p.leftHip, 'rHip': p.rightHip,
      'lAnk': p.leftAnkle, 'rAnk': p.rightAnkle,
    };
    bool seen(String k) => (lm[k]?.likelihood ?? 0) >= _minLikelihood;

    // ── Full body in frame ──────────────────────────────────────────────
    final headSeen = seen('nose');
    final feetSeen = seen('lAnk') || seen('rAnk');
    if (!headSeen && !feetSeen) {
      return _log(shot, p, const PoseCheck(false, 'capture.hint_no_body'));
    }
    if (!feetSeen) {
      return _log(shot, p, const PoseCheck(false, 'capture.hint_step_back'));
    }
    if (!headSeen || p.nose!.y > _headMaxY) {
      return _log(shot, p, const PoseCheck(false, 'capture.hint_head'));
    }
    final ankleY = math.max(p.leftAnkle?.y ?? 0, p.rightAnkle?.y ?? 0);
    if (ankleY < _feetMinY) {
      return _log(shot, p, const PoseCheck(false, 'capture.hint_step_back'));
    }
    // Anything drifting off the left/right edge → recenter.
    for (final k in ['lSh', 'rSh', 'lWr', 'rWr', 'lAnk', 'rAnk']) {
      final l = lm[k];
      if (l != null &&
          l.likelihood >= _minLikelihood &&
          (l.x < _edgeMargin || l.x > 1 - _edgeMargin)) {
        return _log(shot, p, const PoseCheck(false, 'capture.hint_center'));
      }
    }

    if (!seen('lSh') || !seen('rSh')) {
      return _log(shot, p, const PoseCheck(false, 'capture.hint_no_body'));
    }
    final shoulderDx = (p.leftShoulder!.x - p.rightShoulder!.x).abs();

    if (shot == BodyShot.front) {
      // Must face the camera.
      if (shoulderDx < _frontMinShoulderDx) {
        return _log(shot, p, const PoseCheck(false, 'capture.hint_face'));
      }
      // Both arms angled out and down (A-pose).
      final la = _armAngle(p.leftShoulder!, p.leftWrist);
      final ra = _armAngle(p.rightShoulder!, p.rightWrist);
      if (la == null || ra == null) {
        return _log(shot, p, const PoseCheck(false, 'capture.hint_arms_down'));
      }
      // Raised arm → wrist above shoulder → negative angle sentinel.
      if (la < 0 || ra < 0) {
        return _log(shot, p, const PoseCheck(false, 'capture.hint_arms_lower'));
      }
      if (la < _armMinAngleDeg || ra < _armMinAngleDeg) {
        return _log(shot, p, const PoseCheck(false, 'capture.hint_arms_out'));
      }
      if (la > _armMaxAngleDeg || ra > _armMaxAngleDeg) {
        return _log(shot, p, const PoseCheck(false, 'capture.hint_arms_lower'));
      }
      return _log(shot, p, const PoseCheck(true, 'capture.hint_hold'));
    } else {
      // Side: torso in profile, arms hanging at the sides.
      if (shoulderDx > _sideMaxShoulderDx) {
        return _log(shot, p, const PoseCheck(false, 'capture.hint_turn_side'));
      }
      final hipX = ((p.leftHip?.x ?? p.leftShoulder!.x) +
              (p.rightHip?.x ?? p.rightShoulder!.x)) /
          2;
      double spread = 0;
      for (final w in [p.leftWrist, p.rightWrist]) {
        if (w != null && w.likelihood >= _minLikelihood) {
          spread = math.max(spread, (w.x - hipX).abs());
        }
      }
      if (spread > _sideMaxArmSpread) {
        return _log(shot, p, const PoseCheck(false, 'capture.hint_arms_down'));
      }
      return _log(shot, p, const PoseCheck(true, 'capture.hint_hold'));
    }
  }

  /// Angle of the shoulder→wrist vector from vertical, in degrees.
  /// Returns null if the wrist is unseen, or -1 if the wrist is above the
  /// shoulder (arm raised), which callers treat as "lower your arms".
  static double? _armAngle(ARLandmark shoulder, ARLandmark? wrist) {
    if (wrist == null || wrist.likelihood < _minLikelihood) return null;
    final dy = wrist.y - shoulder.y; // down is positive
    if (dy <= 0) return -1;
    final dx = (wrist.x - shoulder.x).abs();
    return math.atan2(dx, dy) * 180 / math.pi;
  }

  static PoseCheck _log(BodyShot shot, PoseResult p, PoseCheck c) {
    if (debug) {
      final dx = (p.leftShoulder != null && p.rightShoulder != null)
          ? (p.leftShoulder!.x - p.rightShoulder!.x).abs().toStringAsFixed(2)
          : '—';
      debugPrint('[PoseGuide] ${shot.name} ok=${c.ok} '
          'hint=${c.hintKey.split('.').last} '
          'nose.y=${p.nose?.y.toStringAsFixed(2)} '
          'ankleY=${math.max(p.leftAnkle?.y ?? 0, p.rightAnkle?.y ?? 0).toStringAsFixed(2)} '
          'shDx=$dx '
          'lArm=${_armAngle(p.leftShoulder ?? const ARLandmark(x: 0, y: 0, likelihood: 0), p.leftWrist)?.toStringAsFixed(0)} '
          'rArm=${_armAngle(p.rightShoulder ?? const ARLandmark(x: 0, y: 0, likelihood: 0), p.rightWrist)?.toStringAsFixed(0)}');
    }
    return c;
  }
}
