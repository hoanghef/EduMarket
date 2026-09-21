// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
library;

import 'dart:html' as html;

void saveFileBytes(List<int> bytes, String fileName, String mimeType) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}

void openInNewTab(String url) {
  html.window.open(url, '_blank');
}
