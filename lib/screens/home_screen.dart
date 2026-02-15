import 'package:flutter/material.dart';
import '../services/x32_service.dart';

class HomeScreen extends StatefulWidget {
  final X32Service x32Service;

  const HomeScreen({super.key, required this.x32Service});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isStreaming = false;
  bool _isRecording = false;
  bool _isScenarioRunning = false;

  late final List<_IntegratedScenario> _scenarios;

  @override
  void initState() {
    super.initState();
    _scenarios = const [
      _IntegratedScenario(
        title: '예배 준비',
        subtitle: 'Worship Prep',
        icon: Icons.meeting_room,
        color: Colors.blue,
        x32SceneIndex: 0,
      ),
      _IntegratedScenario(
        title: '찬양',
        subtitle: 'Praise',
        icon: Icons.music_note,
        color: Colors.orange,
        x32SceneIndex: 1,
      ),
      _IntegratedScenario(
        title: '설교',
        subtitle: 'Sermon',
        icon: Icons.record_voice_over,
        color: Colors.purple,
        x32SceneIndex: 2,
      ),
      _IntegratedScenario(
        title: '성가대',
        subtitle: 'Choir',
        icon: Icons.groups,
        color: Colors.teal,
        x32SceneIndex: 3,
      ),
      _IntegratedScenario(
        title: '기도',
        subtitle: 'Prayer',
        icon: Icons.volunteer_activism,
        color: Colors.green,
        x32SceneIndex: 4,
      ),
      _IntegratedScenario(
        title: 'PC',
        subtitle: 'PC Source',
        icon: Icons.desktop_windows,
        color: Colors.indigo,
        x32SceneIndex: 5,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '통합 시나리오 (Integrated Scenario)',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildCompactStatusPanel(),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
              ),
              itemBuilder: (context, index) {
                if (index < _scenarios.length) {
                  return _buildScenarioCard(_scenarios[index], index + 1);
                }
                return _buildPlaceholderCard(index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runScenario(_IntegratedScenario scenario) async {
    if (_isScenarioRunning) {
      return;
    }

    setState(() {
      _isScenarioRunning = true;
    });

    try {
      await Future.wait([
        _applyX32Scenario(scenario),
        // Reserve slots for other devices to run in parallel.
        Future<void>.value(),
      ]);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${scenario.title} 시나리오 실행')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('시나리오 실행 실패: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isScenarioRunning = false;
        });
      }
    }
  }

  Future<void> _applyX32Scenario(_IntegratedScenario scenario) async {
    final sceneIndex = scenario.x32SceneIndex;
    if (sceneIndex == null) {
      return;
    }
    widget.x32Service.loadScene(sceneIndex);
  }

  Widget _buildCompactStatusPanel() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: widget.x32Service.isConnected,
              builder: (context, isConnected, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? Colors.green.withAlpha(35)
                        : Colors.red.withAlpha(35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune,
                        size: 16,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isConnected ? 'X32 Online' : 'X32 Offline',
                        style: TextStyle(
                          color: isConnected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            _buildStatusChip(
              title: '송출',
              isActive: _isStreaming,
              activeColor: Colors.red,
              onTap: () {
                setState(() {
                  _isStreaming = !_isStreaming;
                });
              },
            ),
            const SizedBox(width: 8),
            _buildStatusChip(
              title: '녹화',
              isActive: _isRecording,
              activeColor: Colors.redAccent,
              onTap: () {
                setState(() {
                  _isRecording = !_isRecording;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required String title,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withAlpha(35)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? activeColor : Colors.transparent,
          ),
        ),
        child: Text(
          '$title ${isActive ? 'ON' : 'OFF'}',
          style: TextStyle(
            color: isActive ? activeColor : Colors.grey[300],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioCard(_IntegratedScenario scenario, int order) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: _isScenarioRunning ? null : () => _runScenario(scenario),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scenario.color.withAlpha(50), width: 2),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scenario.color.withAlpha(30),
                scenario.color.withAlpha(10),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                order.toString().padLeft(2, '0'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Icon(scenario.icon, size: 40, color: scenario.color),
              const SizedBox(height: 10),
              Text(
                scenario.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                scenario.subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (_isScenarioRunning) ...[
                const SizedBox(height: 8),
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(int order) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              order.toString().padLeft(2, '0'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 8),
            Icon(Icons.add_circle_outline, color: Colors.white24, size: 34),
            const SizedBox(height: 8),
            Text(
              '추가 예정',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white54),
            ),
            Text(
              'Coming Soon',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntegratedScenario {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int? x32SceneIndex;

  const _IntegratedScenario({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.x32SceneIndex,
  });
}
