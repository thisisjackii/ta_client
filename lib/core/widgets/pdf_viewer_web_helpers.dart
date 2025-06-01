// lib/core/widgets/pdf_viewer_web_helpers.dart
import 'dart:html' as html;
import 'dart:ui_web'
    as ui_web; // Ensure this is the correct import for platformViewRegistry for your Flutter version.
// For very old versions, it might have been part of 'dart:ui'.
// As of Flutter 3.10+, 'dart:ui_web' is standard.

// This function will be responsible for registering the view factory.
// It's important that any function calling this is only invoked on the web.
void registerPlatformView(
  String viewType,
  html.HtmlElement Function(int viewId) viewFactory,
) {
  ui_web.platformViewRegistry.registerViewFactory(viewType, viewFactory);
}

// Helper to create the IFrameElement
html.IFrameElement createIFrameElement(String embedUrl) {
  return html.IFrameElement()
    ..src = embedUrl
    ..style.border = 'none'
    ..style.width = '100%'
    ..style.height = '100%';
}
