import 'package:flutter/material.dart';
import '../services/propresenter_service.dart';

class PresenterScreen extends StatefulWidget {
  const PresenterScreen({super.key});

  @override
  State<PresenterScreen> createState() => _PresenterScreenState();
}

class _PresenterScreenState extends State<PresenterScreen> {
  late ProPresenterService _proService;

  @override
  void initState() {
    super.initState();
    // Default config from user request
    _proService = ProPresenterService(
      ipAddress: '127.0.0.1', // Assuming local for now, can be parameterized
      port: 1026,
      remotePassword: 'test1',
    );
    _proService.connect();
  }

  @override
  void dispose() {
    _proService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 800,
            height: 450,
            color: Colors.black,
            child: const Center(
              child: Text(
                'Slide Preview (Mock)',
                style: TextStyle(color: Colors.white, fontSize: 32),
              ),
            ),
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
                label: 'Custom Macro', // Placeholder
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sent: $label'),
                duration: const Duration(milliseconds: 300),
              ),
            );
          },
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: large ? 120 : 80,
            height: large ? 120 : 80,
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
            child: Icon(icon, size: large ? 64 : 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
