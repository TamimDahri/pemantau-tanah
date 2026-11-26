import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';
import 'screens/alerts_screen.dart';
import 'screens/district_map_screen.dart';
import 'screens/my_work_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key, this.initialize = true});

  /// Tests set this to false and call [AppState.init] with a fake location.
  final bool initialize;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pemantau Tanah (Demo)',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: RootShell(initialize: initialize),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.initialize});

  final bool initialize;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialize && !appState.ready) appState.init();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        if (!appState.ready) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mendapatkan lokasi untuk data contoh...'),
                ],
              ),
            ),
          );
        }
        final openAlerts =
            appState.alerts.where((a) => a.state == AlertState.open).length;
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                const _DemoBar(),
                Expanded(
                  child: IndexedStack(
                    index: _tab,
                    children: const [
                      DistrictMapScreen(),
                      MyWorkScreen(),
                      AlertsScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Peta',
              ),
              const NavigationDestination(
                icon: Icon(Icons.checklist),
                label: 'Kerja',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: openAlerts > 0,
                  label: Text('$openAlerts'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                label: 'Amaran',
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Always-visible strip: this build is a demo with sample data, and the role
/// can be switched to see the supervisor's view.
class _DemoBar extends StatelessWidget {
  const _DemoBar();

  @override
  Widget build(BuildContext context) {
    final isOfficer = appState.role == Role.fieldOfficer;
    return Container(
      color: AppColors.text,
      padding: const EdgeInsets.only(left: 16, right: 4),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'DEMO · data contoh, tiada pangkalan data',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          PopupMenuButton<Role>(
            tooltip: 'Tukar peranan',
            onSelected: appState.setRole,
            itemBuilder: (context) => const [
              PopupMenuItem(
                  value: Role.fieldOfficer, child: Text('Pegawai kawasan')),
              PopupMenuItem(value: Role.supervisor, child: Text('Penyelia')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isOfficer ? 'Pegawai kawasan' : 'Penyelia',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
