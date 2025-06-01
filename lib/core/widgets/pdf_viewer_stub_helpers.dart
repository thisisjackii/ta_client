// lib/core/widgets/pdf_viewer_stub_helpers.dart

// Define a type alias for the view factory function to match the web version if needed for type safety in the bridge.
// However, since we're just stubbing, dynamic can also work.
// For a stricter approach:
// typedef HtmlElementFactory = dynamic Function(int viewId); // Use dynamic or Object for stub
// For simplicity, we'll just make the function signature match the web one with dynamic types.

void registerPlatformView(
  String viewType,
  dynamic Function(int viewId) viewFactory,
) {
  // This is a stub implementation for non-web platforms.
  // It should ideally never be called if kIsWeb checks are correct.
  throw UnsupportedError(
    'PlatformView registration is not supported on this platform.',
  );
}

// Stub for IFrame creation if needed by a common interface (not strictly necessary here as it's web-only)
dynamic createIFrameElement(String embedUrl) {
  throw UnsupportedError(
    'IFrameElement creation is not supported on this platform.',
  );
}
