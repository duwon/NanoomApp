import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/propresenter_service.dart';

class PresenterScreen extends StatefulWidget {
  const PresenterScreen({super.key});

  @override
  State<PresenterScreen> createState() => _PresenterScreenState();
}

class _PresenterScreenState extends State<PresenterScreen> {
  late ProPresenterService _proService;
  final List<String> _logs = [];
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _proService = ProPresenterService(
      ipAddress: '192.168.1.2',
      port: 1028,
      remotePassword: 'control',
    );
    _proService.connect();
    _proService.startStatusMonitoring();

    // Listen to logs
    _proService.logStream.listen((log) {
      if (mounted) {
        setState(() {
          _logs.add(log);
          // Auto-scroll to bottom
          if (_logScrollController.hasClients) {
            _logScrollController.animateTo(
              _logScrollController.position.maxScrollExtent + 50,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _proService.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Main Control Area
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status Indicator
                ValueListenableBuilder<bool>(
                  valueListenable: _proService.isConnectedNotifier,
                  builder: (context, isConnected, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isConnected
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isConnected ? Icons.check_circle : Icons.error,
                            color: isConnected ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isConnected
                                ? 'Connected to ProPresenter'
                                : 'Disconnected',
                            style: TextStyle(
                              color: isConnected ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Slide Previews
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Current Slide
                    Column(
                      children: [
                        const Text(
                          'Current Slide',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 400,
                          height: 225,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                          child: StreamBuilder<Uint8List?>(
                            stream: _proService.currentSlideImageStream,
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.contain,
                                );
                              }
                              return const Center(
                                child: Text(
                                  'No Signal',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 32),
                    // Next Slide
                    Column(
                      children: [
                        const Text(
                          'Next Slide',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 400,
                          height: 225,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                          child: StreamBuilder<Uint8List?>(
                            stream: _proService.nextSlideImageStream,
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.contain,
                                );
                              }
                              return const Center(
                                child: Text(
                                  'End of Presentation',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(
                      icon: Icons.skip_previous,
                      label: 'Prev',
                      onPressed: () => _proService.triggerPrevious(),
                      color: Colors.grey[800]!,
                    ),
                    const SizedBox(width: 32),
                    _buildControlButton(
                      icon: Icons.play_arrow,
                      label: 'Macro',
                      onPressed: () {},
                      color: Colors.blue[900]!,
                    ),
                    const SizedBox(width: 32),
                    _buildControlButton(
                      icon: Icons.skip_next,
                      label: 'Next',
                      onPressed: () => _proService.triggerNext(),
                      color: Colors.green[800]!,
                      large: true,
                    ),
                    const SizedBox(width: 32),
                    _buildControlButton(
                      icon: Icons.stop,
                      label: 'Clear All',
                      onPressed: () => _proService.clearAll(),
                      color: Colors.red[900]!,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Log Console
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Debug Console',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.grey),
                  Expanded(
                    child: ListView.builder(
                      controller: _logScrollController,
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _logs[index],
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear Logs'),
                    onPressed: () {
                      setState(() {
                        _logs.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool large = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            onPressed();
          },
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: large ? 100 : 70,
            height: large ? 100 : 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 5,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, size: large ? 50 : 32, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
