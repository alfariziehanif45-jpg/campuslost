// Dipakai di Flutter Web (tidak ada dart:io / HttpServer).
// Di web, folder 'admin_web/dist' harus tersedia di dalam folder 'web/'.

Future<String> startAdminServer() async => 'admin_web/dist/index.html';

Future<void> stopAdminServer() async {}
