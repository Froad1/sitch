import 'dart:io';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_static/shelf_static.dart';

void main() async {
  // Створюємо статичний handler для обслуговування файлів з папки build/web
  final staticHandler = createStaticHandler(
    'build/web',
    defaultDocument: 'index.html',
    serveFilesOutsidePath: false,
  );

  // Кастомний handler для /auth/callback
  Handler customHandler = (Request request) async {
    final path = request.url.path;
    
    // Якщо запит на /auth/callback, повертаємо auth_callback.html
    if (path == '/auth/callback' || path.startsWith('/auth/callback?')) {
      final callbackFile = File('build/web/auth_callback.html');
      if (await callbackFile.exists()) {
        final content = await callbackFile.readAsString();
        return Response.ok(
          content,
          headers: {
            'Content-Type': 'text/html; charset=utf-8',
          },
        );
      } else {
        return Response.notFound('auth_callback.html not found');
      }
    }
    
    // Для всіх інших запитів використовуємо статичний handler
    return staticHandler(request);
  };

  // Запускаємо сервер
  final server = await io.serve(
    customHandler,
    InternetAddress.loopbackIPv4,
    8080,
  );

  print('Server running at http://${server.address.host}:${server.port}');
  print('OAuth callback endpoint: http://${server.address.host}:${server.port}/auth/callback');
}
