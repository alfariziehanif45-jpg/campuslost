import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Android/iOS -> server lokal (dart:io). Web -> stub (tanpa dart:io).
import 'admin_server_stub.dart' if (dart.library.io) 'admin_server_io.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  String? _loadError;

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
      final url = await startAdminServer();
      await _controller.loadRequest(Uri.parse(url));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error is StateError ? error.message : error.toString();
      });
    }
  }

  @override
  void dispose() {
    stopAdminServer();
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
              child: SingleChildScrollView(
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
