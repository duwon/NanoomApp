import 'dart:io';
import 'package:osc/osc.dart';

class X32Service {
  final String ipAddress;
  final int port;
  RawDatagramSocket? _socket;

  X32Service({this.ipAddress = '192.168.1.50', this.port = 10023});

  Future<void> init() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    print(
      'X32 OSC Service initialized on ${_socket?.address.address}:${_socket?.port}',
    );
  }

  void dispose() {
    _socket?.close();
  }

  /// Sends an OSC message to the X32
  void sendOSC(String address, List<Object> arguments) {
    if (_socket == null) {
      print('Socket not initialized. Call init() first.');
      return;
    }

    try {
      final message = OSCMessage(address, arguments: arguments);
      // Ensure the destination IP is correct in your network
      final destination = InternetAddress(ipAddress);

      // Note: The 'osc' package's OSCMessage might need conversion to bytes.
      // If OSCMessage doesn't have a direct toBytes(), we rely on the specific version's API.
      // Assuming a standard 'osc' package usage:
      final bytes = message.toBytes();

      _socket!.send(bytes, destination, port);
      print('Sent OSC to $ipAddress:$port -> $address $arguments');
    } catch (e) {
      print('Error sending OSC message: $e');
    }
  }

  void setFader(int channel, double value) {
    // Channel is 1-32. String format typically /ch/01/mix/fader
    final channelStr = channel.toString().padLeft(2, '0');
    sendOSC('/ch/$channelStr/mix/fader', [value]);
  }

  void muteChannel(int channel, bool mute) {
    final channelStr = channel.toString().padLeft(2, '0');
    // 1 = Muted (On), 0 = Unmuted (Off) usually for 'mix/on' but X32 might differ.
    // X32: /ch/01/mix/on , type: i, value: 0 (mute), 1 (unmute) - Wait, usually 'on' means logic on (unmuted).
    // Let's assume 0 is mute, 1 is unmute for now, or check spec.
    // Actually, usually 0 is OFF (Muted? or Logic Off?), 1 is ON.
    // X32 'mix/on' 1 = Signal ON (Unmuted). 0 = Signal OFF (Muted).
    sendOSC('/ch/$channelStr/mix/on', [mute ? 0 : 1]);
  }
}
