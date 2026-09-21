// Platform-independent stub for file download helpers.
library;

void saveFileBytes(List<int> bytes, String fileName, String mimeType) {
  // No-op for non-web environments (unit tests, headless).
}

void openInNewTab(String url) {
  // No-op for non-web environments.
}
