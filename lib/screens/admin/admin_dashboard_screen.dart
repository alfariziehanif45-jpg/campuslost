import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final WebViewController _controller;
  HttpServer? _server;
  StreamSubscription<HttpRequest>? _serverSubscription;
  int _progress = 0;
  String? _loadError;
  static const int _serverPort = 38547;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF7F8FC))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _progress = 100);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() => _loadError = error.description);
            }
          },
        ),
      );
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      if (_server == null) {
        _server = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          _serverPort,
        );
        _serverSubscription = _server!.listen(_serveAssetRequest);
      }
      await _controller.loadRequest(
        Uri.parse(
          'http://127.0.0.1:$_serverPort/admin_web/dist/index.html',
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _loadError = error.toString());
    }
  }

  Future<void> _serveAssetRequest(HttpRequest request) async {
    final requestedPath = Uri.decodeComponent(request.uri.path);
    const assetRoot = 'admin_web/dist/';
    if (!requestedPath.startsWith('/$assetRoot')) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final assetPath = requestedPath.substring(1);
    try {
      final data = await rootBundle.load(assetPath);
      final extension = assetPath.split('.').last.toLowerCase();
      final contentType = switch (extension) {
        'html' => 'text/html; charset=utf-8',
        'js' => 'application/javascript; charset=utf-8',
        'css' => 'text/css; charset=utf-8',
        'json' => 'application/json; charset=utf-8',
        'svg' => 'image/svg+xml',
        'woff' => 'font/woff',
        'woff2' => 'font/woff2',
        _ => 'application/octet-stream',
      };
      request.response.headers.set(HttpHeaders.contentTypeHeader, contentType);
      request.response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      request.response.add(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } catch (_) {
      request.response.statusCode = HttpStatus.notFound;
    }
    await request.response.close();
  }

  @override
  void dispose() {
    _serverSubscription?.cancel();
    _server?.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Panel Admin'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF26345F),
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (_loadError == null)
            WebViewWidget(controller: _controller)
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 42, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'Panel admin tidak dapat dibuka.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _loadError = null;
                          _progress = 0;
                        });
                        _loadDashboard();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ),
          if (_loadError == null && _progress < 100)
            Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(
                value: _progress == 0 ? null : _progress / 100,
                color: const Color(0xFF4358B8),
                backgroundColor: const Color(0xFFE7E9F4),
                minHeight: 2,
              ),
            ),
        ],
      ),
    );
  }
}
