import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

/// Server lokal kecil (127.0.0.1) yang menyajikan hasil build React/Vite
/// dari aset Flutter (admin_web/dist/...).
///
/// Kenapa tidak pakai loadFlutterAsset / file:// ?
/// - Vite menghasilkan <script type="module">, yang DIBLOKIR oleh WebView Android
///   bila dimuat dari file:// (CORS, origin "null").
/// - Firebase Auth/Firestore butuh origin http(s) agar IndexedDB & fetch normal.
HttpServer? _server;

const String _assetRoot = 'admin_web/dist';

const Map<String, String> _mimeTypes = {
  'html': 'text/html; charset=utf-8',
  'js': 'application/javascript; charset=utf-8',
  'mjs': 'application/javascript; charset=utf-8',
  'css': 'text/css; charset=utf-8',
  'json': 'application/json; charset=utf-8',
  'map': 'application/json; charset=utf-8',
  'svg': 'image/svg+xml',
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'gif': 'image/gif',
  'webp': 'image/webp',
  'ico': 'image/x-icon',
  'woff': 'font/woff',
  'woff2': 'font/woff2',
  'ttf': 'font/ttf',
  'txt': 'text/plain; charset=utf-8',
};

String _mimeOf(String path) {
  final dot = path.lastIndexOf('.');
  if (dot == -1) return 'application/octet-stream';
  return _mimeTypes[path.substring(dot + 1).toLowerCase()] ??
      'application/octet-stream';
}

/// Mengembalikan URL halaman admin yang siap dimuat WebView.
Future<String> startAdminServer() async {
  // Pastikan hasil build benar-benar ikut ter-bundle di APK.
  try {
    await rootBundle.load('$_assetRoot/index.html');
  } catch (_) {
    throw StateError(
      'Aset "$_assetRoot/index.html" tidak ditemukan di aplikasi.\n\n'
      'Build dulu panel admin:\n'
      '  cd admin_web\n'
      '  npm install\n'
      '  npm run build\n'
      '  cd ..\n'
      '  flutter clean\n'
      '  flutter pub get\n'
      '  flutter run (atau flutter build apk)',
    );
  }

  await _server?.close(force: true);
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  _server = server;

  server.listen((HttpRequest request) async {
    var path = Uri.decodeComponent(request.uri.path);
    if (path == '/' || path.isEmpty) path = '/index.html';
    // Cegah path traversal.
    if (path.contains('..')) {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }

    try {
      final data = await rootBundle.load('$_assetRoot$path');
      request.response.headers.contentType = ContentType.parse(_mimeOf(path));
      request.response.headers.set('Cache-Control', 'no-cache');
      request.response.add(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } catch (_) {
      request.response.statusCode = HttpStatus.notFound;
    }
    await request.response.close();
  });

  return 'http://127.0.0.1:${server.port}/index.html';
}

Future<void> stopAdminServer() async {
  await _server?.close(force: true);
  _server = null;
}
