/// Cross-platform entry point for saving image bytes as a browser download.
///
/// On web this resolves to the `dart:html` implementation; on every other
/// platform it resolves to the stub (which is never called because callers
/// guard with `kIsWeb`).
export 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart';
