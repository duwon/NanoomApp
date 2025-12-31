import 'package:flutter/material.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCameraControl('Cam 1', Icons.videocam),
          const SizedBox(width: 24),
          _buildCameraControl('Cam 2', Icons.videocam),
          const SizedBox(width: 24),
          _buildCameraControl('Cam 3', Icons.videocam),
        ],
      ),
    );
  }

  Widget _buildCameraControl(String name, IconData icon) {
    return Card(
      child: Container(
        width: 300,
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Container(
                color: Colors.black12,
                child: Center(child: Icon(icon, size: 80, color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Preset 1')),
                Chip(label: Text('Preset 2')),
                Chip(label: Text('Preset 3')),
                Chip(label: Text('Preset 4')),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Icons.arrow_back),
                Icon(Icons.arrow_upward),
                Icon(Icons.arrow_downward),
                Icon(Icons.arrow_forward),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
