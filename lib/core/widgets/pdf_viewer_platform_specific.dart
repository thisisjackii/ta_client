// lib/core/widgets/pdf_viewer_platform_specific.dart
export 'pdf_viewer_stub_helpers.dart' // Stub implementation (default)
    if (dart.library.html) 'pdf_viewer_web_helpers.dart'; // Web implementation
