import 'package:flutter/material.dart';
import '../services/vmix_service.dart';

class VMixScreen extends StatefulWidget {
  final VMixService vMixService;

  const VMixScreen({super.key, required this.vMixService});

  @override
  State<VMixScreen> createState() => _VMixScreenState();
}

class _VMixScreenState extends State<VMixScreen> {
  // Mock state for overlays
  final List<bool> _overlayStates = [false, false, false, false];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top: Transition Buttons
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => widget.vMixService.cut(),
                    child: const Text(
                      'CUT',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => widget.vMixService.fade(500),
                    child: const Text(
                      'AUTO (FADE)',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Input Sources',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),

          // 2. Middle: Input Grid (1-8)
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.6,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                final inputNum = index + 1;
                return Material(
                  color: Theme.of(context).cardColor,
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () =>
                        widget.vMixService.inputActive(inputNum.toString()),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.monitor,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Input $inputNum',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),

          // 3. Bottom: Overlays
          const Text(
            'Overlays',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: Row(
              children: List.generate(4, (index) {
                final overlayNum = index + 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _buildOverlayToggle(overlayNum),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayToggle(int overlayNum) {
    final isActive = _overlayStates[overlayNum - 1];
    return InkWell(
      onTap: () {
        setState(() {
          _overlayStates[overlayNum - 1] = !isActive;
        });
        // Call Overlay command (placeholder function in service might need update, sending generic for now)
        widget.vMixService.sendCommand(
          'OverlayInput$overlayNum',
          params: {'Input': '1'},
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Overlay $overlayNum ${!isActive ? 'ON' : 'OFF'}'),
            duration: const Duration(milliseconds: 500),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.green[900] : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.greenAccent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'OVL $overlayNum',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.white54,
              ),
            ),
            const SizedBox(height: 8),
            Icon(
              isActive ? Icons.toggle_on : Icons.toggle_off,
              color: isActive ? Colors.greenAccent : Colors.grey,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
