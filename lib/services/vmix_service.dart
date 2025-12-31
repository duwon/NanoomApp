import 'package:http/http.dart' as http;

class VMixService {
  final String baseUrl;

  VMixService({this.baseUrl = 'http://127.0.0.1:8088'});

  /// Sends a generic command to vMix
  Future<void> sendCommand(
    String function, {
    Map<String, String>? params,
  }) async {
    final queryParams = {'Function': function};
    if (params != null) {
      queryParams.addAll(params);
    }

    final uri = Uri.parse(
      '$baseUrl/api/',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        print('vMix command sent: $function');
      } else {
        print('vMix command failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending vMix command: $e');
    }
  }

  Future<void> cut() async {
    await sendCommand('Cut');
  }

  Future<void> fade(int duration) async {
    await sendCommand('Fade', params: {'Duration': duration.toString()});
  }

  Future<void> inputPreview(String inputKey) async {
    await sendCommand('PreviewInput', params: {'Input': inputKey});
  }

  Future<void> inputActive(String inputKey) async {
    await sendCommand('ActiveInput', params: {'Input': inputKey});
  }
}
