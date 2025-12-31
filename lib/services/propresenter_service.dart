import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class ProPresenterService {
  final String ipAddress;
  final int port;
  final String remotePassword;
  WebSocketChannel? _channel;
  bool isAuthenticated = false;

  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier(false);
  final _logController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;

  // ProPresenter 7.9+ uses /remote endpoint
  ProPresenterService({
    this.ipAddress = '127.0.0.1',
    this.port = 1026,
    this.remotePassword = 'test1',
  });

  void _log(String message) {
    print(message);
    _logController.add(
      '${DateTime.now().toIso8601String().split('T').last.substring(0, 8)} $message',
    );
  }

  Future<void> connect() async {
    final uri = Uri.parse('ws://$ipAddress:$port/remote');
    try {
      _channel = WebSocketChannel.connect(uri);
      _log('Connecting to ProPresenter at $uri');

      _channel!.stream.listen(
        (message) {
          _log('RX: $message');
          final data = jsonDecode(message);

          // Handle auth response check if needed
          if (data['action'] == 'authenticate') {
            if (data['authenticated'] == 1) {
              isAuthenticated = true;
              isConnectedNotifier.value = true;
              _log('ProPresenter Authenticated!');
            } else {
              _log('Authentication Failed: ${data['error']}');
            }
          }
        },
        onError: (error) {
          _log('Connection Error: $error');
          isAuthenticated = false;
          isConnectedNotifier.value = false;
        },
        onDone: () {
          _log('Connection Closed');
          isAuthenticated = false;
          isConnectedNotifier.value = false;
        },
      );

      // Send Authentication
      _authenticate();
    } catch (e) {
      _log('Connection Failed: $e');
      isConnectedNotifier.value = false;
    }
  }

  void _authenticate() {
    final authMessage = {
      'action': 'authenticate',
      'protocol': '701',
      'password': remotePassword,
    };
    sendJson(authMessage);
  }

  void sendJson(Map<String, dynamic> data) {
    if (_channel != null) {
      final jsonStr = jsonEncode(data);
      _channel!.sink.add(jsonStr);
      _log('TX: $jsonStr');
    } else {
      _log('Cannot send: Not connected');
    }
  }

  // --- State Monitoring ---

  final _currentSlideImageController = StreamController<Uint8List?>.broadcast();
  Stream<Uint8List?> get currentSlideImageStream =>
      _currentSlideImageController.stream;

  final _nextSlideImageController = StreamController<Uint8List?>.broadcast();
  Stream<Uint8List?> get nextSlideImageStream =>
      _nextSlideImageController.stream;

  Timer? _statusTimer;

  void startStatusMonitoring() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (isConnectedNotifier.value) {
        _checkStatus();
      }
    });
  }

  Future<void> _checkStatus() async {
    // Attempt to get active presentation info
    try {
      final url = Uri.parse('http://$ipAddress:$port/v1/presentation/active');
      final response = await http.get(url);

      // Log for debugging (User can see this in the app console)
      // _log('Status Poll (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Try to parse Presentation ID and Slide Index
        // Structure varies, commonly: { "presentation": { "id": { "uuid": "..." } }, "index": 0 }
        String? presentationId;
        int? slideIndex;

        if (data is Map) {
          if (data.containsKey('presentation')) {
            final pres = data['presentation'];
            if (pres is Map && pres.containsKey('id')) {
              final id = pres['id'];
              if (id is Map && id.containsKey('uuid')) {
                presentationId = id['uuid'];
              } else if (id is String) {
                presentationId = id;
              }
            }
          }

          if (data.containsKey('index')) {
            slideIndex = data['index'];
          } else if (data.containsKey('slide_index')) {
            slideIndex = data['slide_index'];
          }
        }

        if (presentationId != null && slideIndex != null) {
          // We have info, fetch valid image
          // _log('Active: $presentationId / $slideIndex');
          _fetchAndEmitImage(presentationId, slideIndex);
        } else {
          // _log('Could not parse active slide info');
        }
      }
    } catch (e) {
      _log('Status Check Failed: $e');
    }
  }

  Future<void> _fetchAndEmitImage(String presentationId, int slideIndex) async {
    // Endpoint: /v1/presentation/{id}/thumbnail/{index}
    try {
      final url = Uri.parse(
        'http://$ipAddress:$port/v1/presentation/$presentationId/thumbnail/$slideIndex',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        _currentSlideImageController.add(response.bodyBytes);

        // Try to look ahead for next slide (simple +1 for now)
        final nextUrl = Uri.parse(
          'http://$ipAddress:$port/v1/presentation/$presentationId/thumbnail/${slideIndex + 1}',
        );
        http.get(nextUrl).then((resp) {
          if (resp.statusCode == 200) {
            _nextSlideImageController.add(resp.bodyBytes);
          } else {
            _nextSlideImageController.add(null);
          }
        });
      } else {
        // _log('Img Fail: ${response.statusCode}');
      }
    } catch (e) {
      // Ignore
    }
  }

  // To fetch actual images, we'll need the slide UUIDs.
  // URL: http://$ipAddress:$port/v1/presentation/{presentation_id}/thumbnail/{slide_index}
  // OR http://$ipAddress:$port/stage/image/{uuid} as per some docs.

  Future<Uint8List?> fetchSlideImage(String uuid) async {
    try {
      final url = Uri.parse('http://$ipAddress:$port/stage/image/$uuid');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      _log('Image Fetch Failed: $e');
    }
    return null;
  }

  void stopStatusMonitoring() {
    _statusTimer?.cancel();
  }

  // --- Commands (HTTP) ---
  // Note: 204 No Content is SUCCESS for triggers!

  Future<void> _sendHttpCommand(String endpoint) async {
    final url = Uri.parse('http://$ipAddress:$port/v1/$endpoint');
    _log('HTTP TX: GET $endpoint');
    try {
      final response = await http.get(url);

      if (response.statusCode == 204) {
        _log('HTTP Success (204)');
      } else if (response.statusCode == 200) {
        _log('HTTP Success (200): ${response.body}');
      } else {
        _log('HTTP Error: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      _log('HTTP Failed: $e');
    }
  }

  void triggerNext() {
    _sendHttpCommand('trigger/next');
  }

  void triggerPrevious() {
    _sendHttpCommand('trigger/prev');
  }

  void clearAll() {
    _sendHttpCommand('clear/all');
  }

  void clearSlide() {
    _sendHttpCommand('clear/slide');
  }

  void dispose() {
    _statusTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    isConnectedNotifier.dispose();
    _currentSlideImageController.close();
    _nextSlideImageController.close();
    _logController.close();
  }
}
