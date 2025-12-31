import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mock states for broadcast
  bool _isStreaming = false;
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Section: Integrated Scenario (2/3 width)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '통합 시나리오 (Integrated Scenario)',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 1.5,
                    children: [
                      _buildScenarioCard(
                        '1. 예배 준비',
                        'Worship Prep',
                        Icons.meeting_room,
                        Colors.blue,
                      ),
                      _buildScenarioCard(
                        '2. 찬양',
                        'Praise',
                        Icons.music_note,
                        Colors.orange,
                      ),
                      _buildScenarioCard(
                        '3. 설교',
                        'Sermon',
                        Icons.person_4,
                        Colors.purple,
                      ),
                      _buildScenarioCard(
                        '4. 광고/축도',
                        'Announcements',
                        Icons.campaign,
                        Colors.teal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 32),

          // Vertical Divider
          Container(width: 1, color: Theme.of(context).dividerColor),

          const SizedBox(width: 32),

          // Right Section: Broadcast Status (1/3 width)
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '방송 상태 (Status)',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildBroadcastButton(
                          title: _isStreaming ? '스트리밍 중지' : '스트리밍 시작',
                          subtitle: _isStreaming ? 'ON AIR' : 'YouTube Live',
                          isActive: _isStreaming,
                          activeColor: Colors.red,
                          icon: Icons.live_tv,
                          onTap: () {
                            setState(() {
                              _isStreaming = !_isStreaming;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isStreaming
                                      ? '방송 시작 (Streaming Started)'
                                      : '방송 종료 (Streaming Stopped)',
                                ),
                                backgroundColor: _isStreaming
                                    ? Colors.red
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _buildBroadcastButton(
                          title: _isRecording ? '녹화 중지' : '녹화 시작',
                          subtitle: _isRecording ? 'REC' : 'Local Recording',
                          isActive: _isRecording,
                          activeColor: Colors.redAccent,
                          icon: Icons.fiber_manual_record,
                          onTap: () {
                            setState(() {
                              _isRecording = !_isRecording;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isRecording
                                      ? '녹화 시작 (Recording Started)'
                                      : '녹화 종료 (Recording Stopped)',
                                ),
                                backgroundColor: _isRecording
                                    ? Colors.redAccent
                                    : null,
                              ),
                            );
                          },
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

  Widget _buildScenarioCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 6, // Increase elevation for "big button" feel
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ), // Softer corners
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$title 시나리오 실행')));
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withAlpha(50), width: 2),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withAlpha(30), color.withAlpha(10)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBroadcastButton({
    required String title,
    required String subtitle,
    required bool isActive,
    required Color activeColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final color = isActive ? activeColor : Colors.grey;
    final backgroundColor = isActive
        ? activeColor.withAlpha(50)
        : Theme.of(context).colorScheme.surfaceVariant;

    return Card(
      elevation: isActive ? 8 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: backgroundColor,
            border: isActive ? Border.all(color: activeColor, width: 3) : null,
          ),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : null,
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
