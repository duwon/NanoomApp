import 'package:flutter/material.dart';
import '../services/x32_service.dart';

class X32Screen extends StatefulWidget {
  final X32Service x32Service;

  const X32Screen({super.key, required this.x32Service});

  @override
  State<X32Screen> createState() => _X32ScreenState();
}

class _X32ScreenState extends State<X32Screen> {
  // Main LR Fader value (0.0 to 1.0)
  double _mainFaderValue = 0.75; // Approx 0dB mock start

  // Mock Scene List
  final List<String> _scenes = [
    '00: Default',
    '01: Worship Start',
    '02: Pastor Sermon',
    '03: Prayer Time',
    '04: Video Playback',
    '05: Acoustic Set',
    '06: Band Full',
    '99: Mute All',
  ];
  int _selectedSceneIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Main Fader (Centerpiece)
          Expanded(
            flex: 2,
            child: Card(
              elevation: 4,
              color: const Color(0xFF1E1E1E), // Darker gray
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'MAIN LR',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                    ),
                    const SizedBox(height: 32),
                    // Fader Area
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // dB Marking (Mock)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('+10', style: TextStyle(color: Colors.grey)),
                              Text('+5', style: TextStyle(color: Colors.grey)),
                              Text(
                                '0',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('-5', style: TextStyle(color: Colors.grey)),
                              Text('-10', style: TextStyle(color: Colors.grey)),
                              Text('-30', style: TextStyle(color: Colors.grey)),
                              Text('-60', style: TextStyle(color: Colors.grey)),
                              Text('-oo', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(width: 24),
                          // The Slider
                          RotatedBox(
                            quarterTurns: 3,
                            child: SizedBox(
                              width: 400, // Physical length of slider
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 12.0,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 16.0,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 28.0,
                                  ),
                                  activeTrackColor: Colors.amber,
                                  thumbColor: Colors.amber,
                                  inactiveTrackColor: Colors.grey[800],
                                ),
                                child: Slider(
                                  value: _mainFaderValue,
                                  onChanged: (value) {
                                    setState(() {
                                      _mainFaderValue = value;
                                    });
                                    // Send to actual service (Assuming Main fader address is distinctive)
                                    // Typically /main/st/mix/fader
                                    widget.x32Service.sendOSC(
                                      '/main/st/mix/fader',
                                      [value],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Value Display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withAlpha(100)),
                      ),
                      child: Text(
                        _faderValueToDb(_mainFaderValue),
                        style: const TextStyle(
                          fontSize: 32,
                          fontFamily: 'monospace',
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Right: Scene List
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'SCENES',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _scenes.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: Colors.white12),
                      itemBuilder: (context, index) {
                        final isSelected = _selectedSceneIndex == index;
                        return ListTile(
                          title: Text(
                            _scenes[index],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? Colors.amber : Colors.white,
                            ),
                          ),
                          leading: Icon(
                            Icons.view_headline,
                            color: isSelected ? Colors.amber : Colors.grey,
                          ),
                          onTap: () {
                            setState(() {
                              _selectedSceneIndex = index;
                            });
                            // Load Scene logic (Mock)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Loading Scene: ${_scenes[index]}',
                                ),
                              ),
                            );
                          },
                          selected: isSelected,
                          selectedTileColor: Colors.amber.withAlpha(20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _selectedSceneIndex >= 0
                      ? () {
                          // Confirm Load
                        }
                      : null,
                  icon: const Icon(Icons.download),
                  label: const Text('GO / LOAD'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Simple mock converter from 0.0-1.0 float to crude dB display
  String _faderValueToDb(double value) {
    if (value == 0) return '-oo dB';
    // X32 fader scale is not linear, this is just a visual approximation
    // 0.75 is roughly 0dB in X32 land usually
    if (value >= 0.75) {
      final db = (value - 0.75) * 40; // 0.25 range -> +10dB
      return '+${db.toStringAsFixed(1)} dB';
    } else {
      // 0.75 range -> -oo to 0
      // Linear approx for simple display
      final db = (1.0 - (value / 0.75)) * -60;
      return '${db.toStringAsFixed(1)} dB';
    }
  }
}
