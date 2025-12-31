import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class ProPresenterService {
  final String ipAddress;
  final int port;
  final String remotePassword;
  WebSocketChannel? _channel;
  bool isAuthenticated = false;

  // ProPresenter 7.9+ uses /remote endpoint
  ProPresenterService({
    this.ipAddress = '127.0.0.1',
    this.port = 1026,
    this.remotePassword = 'test1',
  });

  Future<void> connect() async {
    final uri = Uri.parse('ws://$ipAddress:$port/remote');
    try {
      _channel = WebSocketChannel.connect(uri);
      print('Connecting to ProPresenter at $uri');

      // Listen for messages to handle authentication challenge if needed
      // (Though often we just send the auth frame immediately)
      _channel!.stream.listen(
        (message) {
          print('ProPresenter Message: $message');
          final data = jsonDecode(message);

          // Handle auth response check if needed
          if (data['action'] == 'authenticate' && data['authenticated'] == 1) {
            isAuthenticated = true;
            print('ProPresenter Authenticated!');
          }
        },
        onError: (error) {
          print('ProPresenter Connection Error: $error');
          isAuthenticated = false;
        },
        onDone: () {
          print('ProPresenter Connection Closed');
          isAuthenticated = false;
        },
      );

      // Send Authentication
      _authenticate();
    } catch (e) {
      print('ProPresenter Connection Failed: $e');
    }
  }

  void _authenticate() {
    // Protocol requires initial auth message
    // Format based on community documentation for V7
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
      print('Sent to ProPresenter: $jsonStr');
    } else {
      print('Cannot send, ProPresenter not connected');
    }
  }

  // --- Commands ---

  void triggerNext() {
    // API endpoint: /trigger/next (But via WebSocket action)
    // Common action 'presentationTriggerIndex' or simple triggers.
    // For 7.9+ OpenAPI triggers are usually HTTP, but WS supports actions.
    // Let's try the action format common in simple remote apps
    sendJson({'action': 'presentationTriggerNext'});
  }

  void triggerPrevious() {
    sendJson({'action': 'presentationTriggerPrevious'});
  }

  void clearAll() {
    sendJson({'action': 'clearAll'});
  }

  void clearSlide() {
    sendJson({'action': 'clearSlide'});
  }

  void dispose() {
    _channel?.sink.close(status.goingAway);
  }
}
