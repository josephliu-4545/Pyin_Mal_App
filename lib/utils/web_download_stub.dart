import 'dart:typed_data';

/// Non-web placeholder. Never called on mobile/desktop (callers guard with
/// `kIsWeb`), so it simply throws if somehow invoked.
void downloadBytes(Uint8List bytes, String filename) {
  throw UnsupportedError('Browser download is only available on web.');
}
