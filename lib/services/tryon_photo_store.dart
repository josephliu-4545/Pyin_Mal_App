import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

/// On-device store for the reusable AI try-on person photo.
///
/// The remote `tryOnPhotoUrl` can live on an ephemeral host (e.g. tmpfiles.org
/// expires after ~60 min), which is fatal for a "save once, reuse every time"
/// photo. Persisting the bytes locally means the photo always shows instantly
/// in the profile card and pre-fills the "Your photo" box on the AI Try-On
/// screen, with zero dependence on the remote URL still being alive.
///
/// The file is keyed by the signed-in user's uid, so switching accounts never
/// shows another account's photo.
class TryOnPhotoStore {
  TryOnPhotoStore._();
  static final TryOnPhotoStore instance = TryOnPhotoStore._();

  // In-memory cache keyed by uid so a session's reads are instant while still
  // staying per-account.
  final Map<String, Uint8List> _cache = {};

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'anon';

  Future<File> _file(String uid) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/tryon_person_photo_$uid.jpg');
  }

  /// Persist the current user's try-on photo bytes locally.
  Future<void> save(Uint8List bytes) async {
    final uid = _uid;
    _cache[uid] = bytes;
    try {
      final file = await _file(uid);
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      debugPrint('TryOnPhotoStore.save failed: $e');
    }
  }

  /// Load the current user's saved bytes, or null if none saved yet.
  Future<Uint8List?> load() async {
    final uid = _uid;
    if (_cache.containsKey(uid)) return _cache[uid];
    try {
      final file = await _file(uid);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        _cache[uid] = bytes;
        return bytes;
      }
    } catch (e) {
      debugPrint('TryOnPhotoStore.load failed: $e');
    }
    return null;
  }

  /// Remove the current user's locally stored photo.
  Future<void> clear() async {
    final uid = _uid;
    _cache.remove(uid);
    try {
      final file = await _file(uid);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('TryOnPhotoStore.clear failed: $e');
    }
  }
}
