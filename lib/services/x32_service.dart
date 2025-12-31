import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:osc/osc.dart';
import 'dart:convert';

class X32Service {
  final String ipAddress;
  final int port;
  RawDatagramSocket? _socket;

  // Reactive State
  final ValueNotifier<bool> isConnected = ValueNotifier(false);
  final ValueNotifier<double> mainFaderValue = ValueNotifier(0.0);
  final ValueNotifier<List<String>> scenes = ValueNotifier([]);
  final ValueNotifier<List<bool>> muteGroups = ValueNotifier(
    List.generate(6, (_) => false),
  );

  DateTime? _lastHeartbeat;
  Timer? _keepAliveTimer;

  X32Service({this.ipAddress = '192.168.1.32', this.port = 10023});

  Future<void> init() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket?.listen(_onData);

      print(
        'X32 OSC Service initialized on ${_socket?.address.address}:${_socket?.port}',
      );

      // Start Keep-alive / Polling loop
      _startKeepAlive();
    } catch (e) {
      print('Error initializing X32 Service: $e');
    }
  }

  // Debug: Simulate connection packet
  void simulateTestPacket() {
    print('[X32 DEBUG] Simulating test packet for connection check.');
    _updateConnectionStatus();
  }

  void _onData(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final datagram = _socket?.receive();
      if (datagram != null) {
        // [DEBUG] Log every packet received
        print(
          '[X32 DEBUG] RX from ${datagram.address.address}:${datagram.port} (${datagram.data.length} bytes)',
        );

        if (datagram.address.address == ipAddress) {
          _updateConnectionStatus();
        } else {
          // Warn if we receive data from unexpected IP
          print(
            '[X32 DEBUG] Warning: Rx from unknown IP ${datagram.address.address} (Expected: $ipAddress)',
          );
        }
        _processMessage(datagram.data);
      }
    }
  }

  void _updateConnectionStatus() {
    _lastHeartbeat = DateTime.now();
    if (!isConnected.value) {
      print('[X32 DEBUG] Connection Status -> ONLINE (Source: Heartbeat/Data)');
      isConnected.value = true;
      // Re-subscribe or refresh when connection is restored
      sendOSC('/xremote', []);
      _refreshSceneNames();
    }
  }

  void _processMessage(List<int> data) {
    try {
      // Attempt to parse as single OSC Message
      // Note: X32 often sends Bundles (started with #bundle).
      // The current 'osc' package 'OSCMessage.fromBytes' might fail on Bundles.
      // If it fails, we catch it below.

      // Quick check for Bundle header (first 8 bytes: "#bundle\0")
      if (data.length > 7 &&
          String.fromCharCodes(data.sublist(0, 7)) == '#bundle') {
        print(
          '[X32 DEBUG] Received OSC Bundle (${data.length} bytes) - Parsing not fully supported by this simple implementation.',
        );
        // If possible, try to debug the content string
        try {
          final rawStr = String.fromCharCodes(
            data.map((e) => (e >= 32 && e <= 126) ? e : 46),
          );
          print('[X32 DEBUG] Bundle Raw Content Preview: $rawStr');
        } catch (_) {}
        return;
      }

      final packet = OSCMessage.fromBytes(data);

      // [DEBUG] Log ALL valid messages to see what we get
      print('[X32 DEBUG] Parsed OSC: ${packet.address} ${packet.arguments}');

      if (packet.address == '/main/st/mix/fader') {
        // ... existing fader logic ...
        if (packet.arguments.isNotEmpty && packet.arguments.first is int) {
          mainFaderValue.value = (packet.arguments.first as int).toDouble();
        } else if (packet.arguments.isNotEmpty &&
            packet.arguments.first is double) {
          mainFaderValue.value = packet.arguments.first as double;
        }
      } else if (packet.address.startsWith('/config/mute/')) {
        // ... existing mute logic ...
        try {
          final groupStr = packet.address.split('/').last;
          final groupIdx = int.parse(groupStr) - 1;
          if (groupIdx >= 0 && groupIdx < 6 && packet.arguments.isNotEmpty) {
            final val = packet.arguments.first;
            final isMuted = val == 1 || val == 1.0;
            final newMutes = List<bool>.from(muteGroups.value);
            newMutes[groupIdx] = isMuted;
            muteGroups.value = newMutes;
            print(
              '[X32 DEBUG] Mute Group ${groupIdx + 1} -> ${isMuted ? "ON" : "OFF"}',
            );
          }
        } catch (e) {
          print('[X32 DEBUG] Error parsing mute group: $e');
        }
      } else if (packet.address.startsWith('/show/scene/')) {
        // Standard OSC format (if it comes)
        try {
          final parts = packet.address.split('/');
          if (parts.length >= 4) {
            final idx = int.tryParse(parts[3]);
            if (idx != null && packet.arguments.isNotEmpty) {
              _updateSceneName(idx, packet.arguments[0].toString());
            }
          }
        } catch (e) {
          print('[X32 DEBUG] Error parsing scene dump: $e');
        }
      }
    } catch (e) {
      if (data.length > 4) {
        try {
          // Manual Parsing for X32 "node" messages
          // 1. Split binary data by null bytes (0x00) to find strings
          List<String> tokens = [];
          List<int> buffer = [];

          for (int byte in data) {
            if (byte == 0) {
              if (buffer.isNotEmpty) {
                try {
                  tokens.add(utf8.decode(buffer));
                } catch (_) {
                  tokens.add(String.fromCharCodes(buffer));
                }
                buffer = [];
              }
            } else {
              buffer.add(byte);
            }
          }
          if (buffer.isNotEmpty) {
            try {
              tokens.add(utf8.decode(buffer));
            } catch (_) {
              tokens.add(String.fromCharCodes(buffer));
            }
          }

          // Only log if it looks like a node message to avoid spam
          bool isNode =
              tokens.isNotEmpty &&
              (tokens[0] == 'node' ||
                  (data.length > 4 &&
                      String.fromCharCodes(data.sublist(0, 4)) == 'node'));

          if (isNode) {
            print('[X32 DEBUG] Parsing Node Message (${tokens.length} tokens)');
            // print('[X32 DEBUG] Raw Tokens: $tokens');

            final regex = RegExp(r'/scene/(\d+)\s+"([^"]*)"');

            for (int i = 0; i < tokens.length; i++) {
              final token = tokens[i];
              if (token.startsWith('/-show/showfile/scene/')) {
                // Token contains everything: path, id, name, etc.
                // e.g. /-show/showfile/scene/060 "Invocation" "" ...
                final match = regex.firstMatch(token);
                if (match != null) {
                  final idxStr = match.group(1);
                  final name = match.group(2);
                  final idx = int.tryParse(idxStr ?? '');

                  if (idx != null && name != null) {
                    print('[X32 DEBUG] Extracted: Scene $idx = "$name"');
                    _updateSceneName(idx, name);
                  }
                } else {
                  print('[X32 DEBUG] Regex could not match token: $token');
                }
              }
            }
          }
        } catch (me) {
          print('[X32 DEBUG] Manual Parsing Exception: $me');
        }
      }
    }
  }

  void _updateSceneName(int idx, String name) {
    List<String> currentScenes = List.from(scenes.value);
    if (currentScenes.length <= idx) {
      while (currentScenes.length <= idx) {
        currentScenes.add(
          '${currentScenes.length.toString().padLeft(2, '0')}: ',
        );
      }
    }
    final newName = '${idx.toString().padLeft(2, '0')}: $name';
    if (currentScenes[idx] != newName) {
      currentScenes[idx] = newName;
      scenes.value = currentScenes;
    }
  }

  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 9), (timer) {
      sendOSC('/xremote', []);
      if (_lastHeartbeat != null &&
          DateTime.now().difference(_lastHeartbeat!) >
              const Duration(seconds: 15)) {
        if (isConnected.value) isConnected.value = false;
      }
      if (!isConnected.value) {
        sendOSC('/xinfo', []);
        sendOSC('/main/st/mix/fader', []);
      }
    });
    sendOSC('/xremote', []);
    sendOSC('/xinfo', []);
    sendOSC('/main/st/mix/fader', []);
    for (int i = 1; i <= 6; i++) sendOSC('/config/mute/$i', []);
    _refreshSceneNames();
  }

  void _refreshSceneNames() {
    print('[X32 DEBUG] Requesting Scene Dump (/showdump)...');
    // Try both formats to be sure
    sendOSC('/showdump', []);
    sendOSC('/showdump', ['none', 'none', 'none']); // Some docs say 3 args
  }

  void dispose() {
    _keepAliveTimer?.cancel();
    _socket?.close();
  }

  /// Sends an OSC message to the X32
  void sendOSC(String address, List<Object> arguments) {
    if (_socket == null) return; // Silent fail if not init

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
      // print('Sent OSC to $ipAddress:$port -> $address $arguments');
    } catch (e) {
      print('Error sending OSC message: $e');
    }
  }

  // Request scene list (Mock-ish implementation as X32 requires separate file handling for full list)
  // Real X32: Iterate /load, or read file, complexity is high.
  // We will just generate a standard list for UI for now.
  List<String> getSceneList() {
    return List.generate(100, (index) {
      final num = index.toString().padLeft(2, '0');
      return '$num: Scene $num'; // Placeholder names
    });
  }

  void loadScene(int index) {
    // X32 Scene Recall: /action/goqueue, or -action/goscene
    // Most dependable: /load , i , index
    sendOSC('/load', ['scene', index]);
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

  void toggleMuteGroup(int groupIndex) {
    // groupIndex 1-6
    // We need to know current state to toggle properly, or just send valid.
    // X32 Mute Group: /config/mute/1 , value 1(ON/Muted) or 0(OFF).
    // Use stored state
    final bool currentMute = muteGroups.value[groupIndex - 1];
    final bool newMute = !currentMute;

    sendOSC('/config/mute/$groupIndex', [newMute ? 1 : 0]);
    // Optimistic UI update
    List<bool> current = List.from(muteGroups.value);
    current[groupIndex - 1] = newMute;
    muteGroups.value = current;
  }
}
