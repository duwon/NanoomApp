import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart';
import 'package:ndi_windows_player/ndi_windows_player.dart';
import 'dart:async';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  // NDI Sources
  final List<String> _ndiSources = ['No Source'];
  String _selectedSource = 'No Source';
  String _statusMessage = 'Ready';

  Discovery? _discovery;
  bool _isScanning = false;

  // NDI Player Controller (Mock/Placeholder if actual type differs, usually implicitly handled by widget or controller)
  // The ndi_windows_player example uses simple widget direct usage or a controller.
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    startScanning();
  }

  @override
  void dispose() {
    stopScanning();
    super.dispose();
  }

  Future<void> startScanning() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _statusMessage = 'Starting discovery for _ndi._tcp...';
      _ndiSources.clear();
      _ndiSources.add('No Source');
      _selectedSource = 'No Source';
    });

    try {
      _discovery = await startDiscovery('_ndi._tcp');

      setState(() {
        _statusMessage = 'Discovery active. Waiting for services...';
      });

      _discovery!.addListener(() {
        if (!mounted) return;
        final services = _discovery!.services;
        print('NDI Discovery Update: Found ${services.length} services');

        setState(() {
          final foundNames = services
              .map((s) => s.name ?? 'Unknown Device')
              .toList();

          for (var name in foundNames) {
            print('Found NDI Source: $name');
            if (!_ndiSources.contains(name)) {
              _ndiSources.add(name);
              _statusMessage = 'Found: $name';
            }
          }
          if (foundNames.isEmpty) {
            _statusMessage = 'Scanning... (No sources found yet)';
          }
        });
      });
    } catch (e) {
      print('Error starting NDI discovery: $e');
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusMessage = 'Error: $e';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Discovery Error: $e')));
      }
    }
  }

  Future<void> stopScanning() async {
    if (_discovery != null) {
      await stopDiscovery(_discovery!);
      _discovery = null;
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Control Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.connected_tv, size: 28),
              const SizedBox(width: 16),
              const Text(
                'NDI Source:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _ndiSources.contains(_selectedSource)
                          ? _selectedSource
                          : _ndiSources.first,
                      icon: const Icon(Icons.arrow_drop_down),
                      iconSize: 32,
                      elevation: 16,
                      isExpanded: true,
                      style: Theme.of(context).textTheme.bodyLarge,
                      onChanged: (String? newValue) {
                        setState(() {
                          if (newValue != null) {
                            _selectedSource = newValue;
                            // Reset player state if needed or widget will rebuild with new source name
                          }
                        });
                      },
                      items: _ndiSources.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: () async {
                  await stopScanning();
                  await startScanning();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Scanning for NDI sources...'),
                      ),
                    );
                  }
                },
                icon: _isScanning
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh Sources',
              ),
            ],
          ),
        ),

        // 2. Main NDI Video Area
        Expanded(
          child: Container(
            color: Colors.black,
            width: double.infinity,
            child: _selectedSource != 'No Source'
                // Reverting NdiTextureWidget usage as it likely caused the build error due to missing native setup or API mismatch.
                // Keeping placeholder for now to ensure app runs.
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Streaming: $_selectedSource',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '(NDI Player Integration Pending Native Setup)',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.signal_wifi_off,
                          size: 64,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '소스를 선택해주세요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.grey[400],
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
