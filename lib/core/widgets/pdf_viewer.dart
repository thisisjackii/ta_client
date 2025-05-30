import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // Still needed for native
import 'package:dio/dio.dart'; // Still needed for native download

// --- Conditional Imports for Platform Views & dart:io ---
// For dart:io on native
import 'dart:io' as io;
// For IFrameElement on web
import 'dart:html' as html; // Only available on web
// For PlatformViewRegistry on web (Flutter 3.10+)
// If using older Flutter, you might need a different import or approach for ui.platformViewRegistry
import 'dart:ui_web' as ui_web;

// For path_provider on native
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PdfViewer extends StatefulWidget {
  final String
  pdfUrl; // This should be the Google Drive SHARE link for iframe, or direct download for native
  final String title;

  const PdfViewer({super.key, required this.pdfUrl, this.title = 'Informasi'});

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  // For Native
  String? _localPdfPath;
  // For Web (using IFrame, so no bytes needed here)
  // Uint8List? _pdfBytes; // No longer needed for web if using IFrame

  bool _isLoading = true; // Still used for native loading
  String? _errorMessage;
  int _currentPage = 0; // For native PDFView
  int _totalPages = 0; // For native PDFView
  PDFViewController? _pdfViewController; // For native PDFView
  CancelToken _cancelToken = CancelToken(); // For native download

  // Unique view type for the IFrame
  late String _iframeViewType;

  @override
  void initState() {
    super.initState();
    _iframeViewType = 'pdf-iframe-viewer-${widget.pdfUrl.hashCode}';

    if (kIsWeb) {
      // For web, register the IFrame view factory
      // This needs to be done only once per view type.
      // Doing it in initState is generally fine.
      ui_web.platformViewRegistry.registerViewFactory(
        _iframeViewType,
        (int viewId) => html.IFrameElement()
          ..src =
              _getGoogleDriveEmbedUrl(widget.pdfUrl) // Use embeddable URL
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%',
      );
      setState(() {
        _isLoading =
            false; // For web, iframe loads itself, so app is not "loading" PDF bytes
      });
    } else {
      // For native, load PDF as before
      _loadNativePdf();
    }
  }

  String _getGoogleDriveEmbedUrl(String shareUrl) {
    // Assuming shareUrl is like: https://drive.google.com/file/d/FILE_ID/view?usp=sharing
    // or uc?export=download&id=FILE_ID
    // We need to extract FILE_ID and construct a /preview or /embed link
    Uri uri = Uri.parse(shareUrl);
    String? fileId;
    if (uri.pathSegments.contains('file') && uri.pathSegments.contains('d')) {
      int dIndex = uri.pathSegments.indexOf('d');
      if (dIndex + 1 < uri.pathSegments.length) {
        fileId = uri.pathSegments[dIndex + 1];
      }
    } else if (uri.queryParameters.containsKey('id')) {
      fileId = uri.queryParameters['id'];
    }

    if (fileId != null) {
      // Google Drive often uses /preview for a good embeddable view
      return 'https://drive.google.com/file/d/$fileId/preview';
      // Alternatively, some use an /embed path, but /preview is common
      // return 'https://drive.google.com/embeddedfolderview?id=$fileId#pdfviewer'; // This is more for folders
      // return 'https://docs.google.com/gview?url=${Uri.encodeComponent(widget.pdfUrl)}&embedded=true'; // General Google Docs viewer for any URL
    }
    // Fallback if ID extraction fails, though this might not work well
    debugPrint(
      "Could not extract FILE_ID from Google Drive URL: $shareUrl. Using original URL for IFrame.",
    );
    return shareUrl; // Or throw error
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _cancelToken.cancel("PDF Viewer disposed for native");
    }
    super.dispose();
  }

  // --- Native Specific File Path Logic ---
  Future<String> _getNativeFilePath(String url) async {
    if (kIsWeb) throw UnsupportedError("File path ops not on web.");
    final dir = await getTemporaryDirectory();
    final fileName =
        '${p.basename(url).split("?").first.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_')}_${url.hashCode}.pdf';
    return p.join(dir.path, fileName);
  }

  Future<void> _downloadPdfWithDioToNativeFile(
    io.File file,
    String url,
    CancelToken cancelToken,
  ) async {
    if (kIsWeb) throw UnsupportedError("File download to path not on web.");
    Dio dio = Dio();
    try {
      // For native, ensure you use a direct download link if widget.pdfUrl was changed for iframe
      // However, CustomAppBar should pass the direct download link for native.
      String nativeDownloadUrl = url;
      if (url.contains("/preview") || url.contains("/view")) {
        // Attempt to convert to download link if it looks like a share/preview link
        Uri uri = Uri.parse(url);
        String? fileId;
        if (uri.pathSegments.contains('file') &&
            uri.pathSegments.contains('d')) {
          int dIndex = uri.pathSegments.indexOf('d');
          if (dIndex + 1 < uri.pathSegments.length)
            fileId = uri.pathSegments[dIndex + 1];
        }
        if (fileId != null)
          nativeDownloadUrl =
              'https://drive.google.com/uc?export=download&id=$fileId';
      }

      await dio.download(
        nativeDownloadUrl, // Use the potentially converted download URL
        file.path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint(
              'Native Download progress: ${(received / total * 100).toStringAsFixed(0)}%',
            );
          }
        },
      );
      if (!await file.exists() || await file.length() == 0) {
        throw Exception(
          'Dio download to file completed but file is missing or empty.',
        );
      }
    } on DioException catch (e) {
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      if (e.type == DioExceptionType.cancel) rethrow;
      throw Exception(
        'Gagal mengunduh PDF ke file (Dio): ${e.response?.statusCode ?? e.message}',
      );
    } catch (e) {
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }
  // --- End Native Specific ---

  Future<void> _loadNativePdf() async {
    // Renamed from _loadPdf
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _localPdfPath = null;
    });

    _cancelToken = CancelToken();

    try {
      // NATIVE Implementation
      final localPath = await _getNativeFilePath(widget.pdfUrl);
      final file = io.File(localPath);
      bool needsDownload = true;

      if (await file.exists()) {
        final lastModified = await file.lastModified();
        if (DateTime.now().difference(lastModified).inDays <= 1 &&
            await file.length() > 0) {
          debugPrint('PDF Native: Loading PDF from cache: $localPath');
          needsDownload = false;
        } else {
          debugPrint(
            'PDF Native: Cached PDF is old or empty, re-downloading: $localPath',
          );
        }
      } else {
        debugPrint('PDF Native: PDF not in cache, downloading: $localPath');
      }

      if (needsDownload) {
        await _downloadPdfWithDioToNativeFile(
          file,
          widget.pdfUrl,
          _cancelToken,
        );
      }

      if (!await file.exists() || await file.length() == 0) {
        throw Exception(
          'PDF Native: Downloaded PDF file is empty or does not exist.',
        );
      }
      _localPdfPath = localPath;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        debugPrint('PDF download cancelled: ${e.message}');
        if (mounted) setState(() => _isLoading = false);
      } else {
        debugPrint('Error loading PDF: $e');
        if (mounted) {
          setState(() {
            _errorMessage = 'Gagal memuat PDF (Native): ${e.toString()}';
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: (kIsWeb || _totalPages <= 1)
            ? null
            : <Widget>[
                // Simpler actions for web or single page PDF
                if (_pdfViewController != null)
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      if (_currentPage > 0)
                        _pdfViewController!.setPage(_currentPage - 1);
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Center(
                    child: Text('${_currentPage + 1}/$_totalPages'),
                  ),
                ),
                if (_pdfViewController != null)
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      if (_currentPage < _totalPages - 1)
                        _pdfViewController!.setPage(_currentPage + 1);
                    },
                  ),
              ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && !kIsWeb) {
      // Only show app-level loading for native
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: kIsWeb ? null : _loadNativePdf,
                child: const Text('Coba Lagi'),
              ), // Retry only for native
            ],
          ),
        ),
      );
    }

    if (kIsWeb) {
      // For web, we directly use HtmlElementView with the registered IFrame.
      // The IFrame itself handles loading its content.
      return HtmlElementView(viewType: _iframeViewType);
    } else {
      // Native
      if (_localPdfPath != null) {
        return PDFView(
          filePath: _localPdfPath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: false,
          pageFling: true,
          pageSnap: true,
          defaultPage: _currentPage,
          fitPolicy: FitPolicy.BOTH,
          preventLinkNavigation: false,
          onRender: (pages) {
            if (mounted) setState(() => _totalPages = pages ?? 0);
          },
          onError: (error) {
            if (mounted) setState(() => _errorMessage = error.toString());
          },
          onPageError: (page, error) {
            if (mounted)
              setState(
                () => _errorMessage = 'Halaman $page: ${error.toString()}',
              );
          },
          onViewCreated: (controller) => _pdfViewController = controller,
          onPageChanged: (page, total) {
            if (mounted && page != null) setState(() => _currentPage = page);
          },
        );
      } else {
        // This case should ideally be covered by _isLoading for native
        return const Center(child: Text('Tidak ada jalur PDF lokal (Native).'));
      }
    }
  }
}
