import 'dart:html' as html;
import 'dart:typed_data';

/// Triggers a browser "Save as" download of [bytes] as [filename].
void downloadBytes(Uint8List bytes, String filename) {
  final blob = html.Blob(<dynamic>[bytes], 'image/jpeg');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
