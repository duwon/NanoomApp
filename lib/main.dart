import 'package:flutter/material.dart';
import 'services/vmix_service.dart';
import 'services/x32_service.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/vmix_screen.dart';
import 'screens/presenter_screen.dart';
import 'screens/x32_screen.dart';
import 'screens/broadcast_screen.dart';

void main() {
  runApp(const NanoomApp());
}

class NanoomApp extends StatelessWidget {
  const NanoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Church Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
          surface: Colors.grey[900], // Darker surface for better contrast
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late VMixService _vmixService;
  late X32Service _x32Service;

  @override
  void initState() {
    super.initState();
    _vmixService = VMixService();
    _x32Service = X32Service();
    _x32Service.init();
  }

  @override
  void dispose() {
    _x32Service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Church Integrated Control'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Home'),
              Tab(icon: Icon(Icons.camera_alt), text: 'Camera'),
              Tab(icon: Icon(Icons.video_settings), text: 'vMix'),
              Tab(icon: Icon(Icons.slideshow), text: 'Presenter'),
              Tab(icon: Icon(Icons.tune), text: 'X32'),
              Tab(icon: Icon(Icons.broadcast_on_personal), text: 'Broadcast'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            HomeScreen(x32Service: _x32Service),
            const CameraScreen(),
            VMixScreen(vMixService: _vmixService),
            const PresenterScreen(),
            X32Screen(x32Service: _x32Service),
            const BroadcastScreen(),
          ],
        ),
      ),
    );
  }
}
