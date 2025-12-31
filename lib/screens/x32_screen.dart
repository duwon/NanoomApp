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
  void initState() {
    super.initState();
    // Initialize scene list
    _scenes.clear();
    _scenes.addAll(widget.x32Service.getSceneList());

    // Sync initial state from service
    _mainFaderValue = widget.x32Service.mainFaderValue.value;

    // Listen to external updates
    widget.x32Service.mainFaderValue.addListener(_onFaderUpdate);
  }

  @override
  void dispose() {
    widget.x32Service.mainFaderValue.removeListener(_onFaderUpdate);
    super.dispose();
  }

  void _onFaderUpdate() {
    setState(() {
      _mainFaderValue = widget.x32Service.mainFaderValue.value;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Header Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: widget.x32Service.isConnected,
                  builder: (context, isConnected, _) {
                    return Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isConnected ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isConnected ? Colors.green : Colors.red)
                                    .withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isConnected ? 'ONLINE' : 'OFFLINE',
                          style: TextStyle(
                            color: isConnected ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (!isConnected) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Main Content divided into 3 Columns
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. SCENES (Flex 12)
                Expanded(
                  flex: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'SCENES',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ValueListenableBuilder<List<String>>(
                            valueListenable: widget.x32Service.scenes,
                            builder: (context, scenesList, _) {
                              final displayScenes = scenesList.isNotEmpty
                                  ? scenesList
                                  : _scenes;
                              return Column(
                                children: [
                                  Expanded(
                                    child: ListView.separated(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: displayScenes.length,
                                      separatorBuilder: (context, index) =>
                                          const Divider(color: Colors.white12),
                                      itemBuilder: (context, index) {
                                        final isSelected =
                                            _selectedSceneIndex == index;
                                        return ListTile(
                                          title: Text(
                                            displayScenes[index],
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? Colors.amber
                                                  : Colors.white,
                                            ),
                                          ),
                                          leading: Icon(
                                            Icons.view_headline,
                                            color: isSelected
                                                ? Colors.amber
                                                : Colors.grey,
                                          ),
                                          onTap: () {
                                            setState(() {
                                              _selectedSceneIndex = index;
                                            });
                                          },
                                          selected: isSelected,
                                          selectedTileColor: Colors.amber
                                              .withOpacity(0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _selectedSceneIndex >= 0
                                            ? () {
                                                widget.x32Service.loadScene(
                                                  _selectedSceneIndex,
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Loading Scene: ${displayScenes[_selectedSceneIndex]}',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              }
                                            : null,
                                        icon: const Icon(Icons.download),
                                        label: const Text('GO / LOAD SCENE'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 20,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // 2. MAIN LR (Flex 3)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'MAIN LR',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Card(
                          elevation: 4,
                          color: const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Fader Area
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // dB Marking
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: const [
                                          Text(
                                            '+10',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 10,
                                            ),
                                          ),
                                          Text(
                                            '0',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                          Text(
                                            '-10',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 10,
                                            ),
                                          ),
                                          Text(
                                            '-30',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 10,
                                            ),
                                          ),
                                          Text(
                                            '-oo',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      // The Slider
                                      RotatedBox(
                                        quarterTurns: 3,
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              return SliderTheme(
                                                data: SliderTheme.of(context).copyWith(
                                                  trackHeight: 12.0,
                                                  thumbShape:
                                                      const RoundSliderThumbShape(
                                                        enabledThumbRadius:
                                                            16.0,
                                                      ),
                                                  overlayShape:
                                                      const RoundSliderOverlayShape(
                                                        overlayRadius: 28.0,
                                                      ),
                                                  activeTrackColor:
                                                      Colors.amber,
                                                  thumbColor: Colors.amber,
                                                  inactiveTrackColor:
                                                      Colors.grey[800],
                                                ),
                                                child: Slider(
                                                  value: _mainFaderValue,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _mainFaderValue = value;
                                                    });
                                                    widget.x32Service.sendOSC(
                                                      '/main/st/mix/fader',
                                                      [value],
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Value Display (Reduced Font Size)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.amber.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Text(
                                    _faderValueToDb(_mainFaderValue),
                                    style: const TextStyle(
                                      fontSize: 20, // Reduced from 32
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
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // 3. MUTE GROUPS (Flex 2)
                Expanded(
                  flex: 2, // Narrow column
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'MUTE',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: ValueListenableBuilder<List<bool>>(
                            valueListenable: widget.x32Service.muteGroups,
                            builder: (context, muteStatus, _) {
                              return Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (index) {
                                  final groupNum = index + 1;
                                  final isMuted = muteStatus[index];
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          widget.x32Service.toggleMuteGroup(
                                            groupNum,
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: isMuted
                                                ? Colors.red
                                                : Colors.grey[800],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: isMuted
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.red
                                                          .withOpacity(0.5),
                                                      blurRadius: 8,
                                                    ),
                                                  ]
                                                : [],
                                            border: Border.all(
                                              color: isMuted
                                                  ? Colors.redAccent
                                                  : Colors.grey,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '$groupNum',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Accurate X32 Fader to dB conversion
  String _faderValueToDb(double value) {
    if (value <= 0) return '-oo dB';

    // X32 Fader Curve Points:
    // 1.0  -> +10 dB
    // 0.75 ->   0 dB
    // 0.5  -> -10 dB
    // 0.25 -> -30 dB
    // 0.0  -> -oo dB

    double db;
    if (value >= 0.75) {
      // 0.75 - 1.0 covers 0 dB to +10 dB
      // (value - 0.75) / 0.25 * 10
      db = (value - 0.75) * 40;
    } else if (value >= 0.5) {
      // 0.5 - 0.75 covers -10 dB to 0 dB
      // (value - 0.5) / 0.25 * 10 - 10
      db = ((value - 0.5) * 40) - 10;
    } else if (value >= 0.25) {
      // 0.25 - 0.5 covers -30 dB to -10 dB (Range 20dB)
      // (value - 0.25) / 0.25 * 20 - 30
      db = ((value - 0.25) * 80) - 30;
    } else {
      // 0.0 - 0.25 covers -oo to -30 dB
      // Approximating -60dB at roughly 0.0625
      // Let's just map linearly 0.0-0.25 to -90 to -30
      db = (value * 240) - 90;
      if (db < -90) return '-oo dB'; // consistent footer
    }

    // Format handling
    String sign = db > 0 ? '+' : '';
    // Avoid "-0.0"
    if (db > -0.1 && db < 0.1) sign = '';
    return '$sign${db.toStringAsFixed(1)} dB';
  }
}
