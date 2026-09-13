import 'dart:async';
import 'dart:io';

import 'package:kazumi/services/logging/logger.dart';

/// LAN QR input bridge, modelled after the BT project's QR search.
///
/// The TV app runs a tiny HTTP server on the local network. A QR code next to
/// a text field encodes `http://<tv-ip>:<port>/?t=<target>`; the phone opens
/// that page, types on a full keyboard and hits send, and the bound target
/// receives the text immediately (no cloud service involved).
class TvQrInputService {
  TvQrInputService._();

  static final TvQrInputService instance = TvQrInputService._();

  static const int _basePort = 18765;

  HttpServer? _server;
  String? _baseUrl;
  bool _binding = false;
  final Map<String, void Function(String text)> _targets = {};

  /// URL that QR codes should encode, or null while the server is starting
  /// up or failed to bind.
  String? get baseUrl => _baseUrl;

  /// Registers a text target and returns the URL to encode as QR, or null if
  /// the LAN server could not be started.
  Future<String?> bindTarget(
      String id, void Function(String text) onText) async {
    final ok = await _ensureServer();
    if (!ok) return null;
    _targets[id] = onText;
    return '$_baseUrl/?t=$id';
  }

  void unbindTarget(String id) {
    _targets.remove(id);
  }

  Future<bool> _ensureServer() async {
    if (_server != null) return true;
    if (_binding) return false;
    _binding = true;
    try {
      for (var port = _basePort; port < _basePort + 10; port++) {
        try {
          final server =
              await HttpServer.bind(InternetAddress.anyIPv4, port).timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw const SocketException('bind timeout'),
          );
          await _onBound(server);
          return true;
        } catch (e) {
          KazumiLogger().w('TvQrInput: bind failed on $port', error: e);
        }
      }
      return false;
    } finally {
      _binding = false;
    }
  }

  Future<void> _onBound(HttpServer server) async {
    _server = server;
    final ip = await _lanAddress();
    if (ip == null) {
      KazumiLogger().w('TvQrInput: no LAN IPv4 address found');
      return;
    }
    _baseUrl = 'http://$ip:${server.port}';
    KazumiLogger().i('TvQrInput: serving on $_baseUrl');
    server.listen(
      (request) => unawaited(_handle(request)),
      onError: (Object e) =>
          KazumiLogger().w('TvQrInput: server error', error: e),
      onDone: () => _server = null,
      cancelOnError: false,
    );
  }

  Future<String?> _lanAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback) return address.address;
        }
      }
    } catch (e) {
      KazumiLogger().w('TvQrInput: listing interfaces failed', error: e);
    }
    return null;
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      final uri = request.uri;
      if (uri.path == '/send') {
        final id = uri.queryParameters['t'] ?? '';
        final text = (uri.queryParameters['text'] ?? '').trim();
        final target = _targets[id];
        if (target != null && text.isNotEmpty) {
          target(text);
          await _respond(request, _sentPage(text));
        } else {
          await _respond(request, _messagePage('发送失败：目标不存在或内容为空'));
        }
        return;
      }
      final id = uri.queryParameters['t'] ?? '';
      await _respond(request, _inputPage(id));
    } catch (e) {
      KazumiLogger().w('TvQrInput: request failed', error: e);
      try {
        await _respond(request, _messagePage('处理失败，请重试'));
      } catch (_) {}
    }
  }

  Future<void> _respond(HttpRequest request, String html) async {
    request.response.headers.contentType =
        ContentType('text', 'html', charset: 'utf-8');
    request.response.write(html);
    await request.response.close();
  }

  String _inputPage(String id) => '''
<!DOCTYPE html><html lang="zh"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>My-Kazumi-TV 输入</title>
<style>
body{font-family:sans-serif;max-width:520px;margin:0 auto;padding:24px;}
input{width:100%;box-sizing:border-box;font-size:20px;padding:12px;border:1px solid #bbb;border-radius:8px;}
button{width:100%;font-size:20px;padding:12px;margin-top:12px;border:0;border-radius:8px;background:#4f6ef2;color:#fff;}
.hint{color:#777;font-size:14px;margin-top:10px;text-align:center;}
</style></head><body>
<h3>发送文字到电视</h3>
<form action="/send" method="get">
<input type="hidden" name="t" value="$id">
<input name="text" placeholder="输入文字" autofocus autocomplete="off">
<button type="submit">发送并开始搜索</button>
</form>
<p class="hint">请保持手机与电视在同一局域网</p>
</body></html>''';

  String _sentPage(String text) {
    final shown = text.length > 24 ? '${text.substring(0, 24)}…' : text;
    return '''
<!DOCTYPE html><html lang="zh"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>已发送</title>
<style>body{font-family:sans-serif;max-width:520px;margin:0 auto;padding:40px 24px;text-align:center;}
a{display:inline-block;margin-top:16px;font-size:18px;color:#4f6ef2;}</style></head><body>
<h3>✅ 已发送到电视</h3>
<p>内容：$shown</p>
<a href="javascript:history.back()">← 继续输入</a>
</body></html>''';
  }

  String _messagePage(String message) => '''
<!DOCTYPE html><html lang="zh"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>My-Kazumi-TV</title></head>
<body style="font-family:sans-serif;text-align:center;padding:48px 24px;">
<p>$message</p><a href="javascript:history.back()">← 返回</a></body></html>''';
}
