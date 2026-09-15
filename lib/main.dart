import 'package:flutter/material.dart';

import 'pages/create_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/history_page.dart';
import 'pages/scanner_page.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QrlyBootstrap());
}

class QrlyBootstrap extends StatefulWidget {
  const QrlyBootstrap({super.key});

  @override
  State<QrlyBootstrap> createState() => _QrlyBootstrapState();
}

class _QrlyBootstrapState extends State<QrlyBootstrap> {
  final state = AppState();

  @override
  void initState() {
    super.initState();
    state.load();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: 'QRly',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: QrlyShell(state: state),
        ),
      );
}

class QrlyShell extends StatefulWidget {
  const QrlyShell({super.key, required this.state});
  final AppState state;

  @override
  State<QrlyShell> createState() => _QrlyShellState();
}

class _QrlyShellState extends State<QrlyShell> {
  int index = 0;

  late final pages = [
    DashboardPage(state: widget.state, navigate: _navigate),
    CreatePage(state: widget.state),
    ScannerPage(state: widget.state),
    HistoryPage(state: widget.state),
  ];

  void _navigate(int value) => setState(() => index = value);

  static const destinations = [
    NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Overview'),
    NavigationDestination(icon: Icon(Icons.add_box_outlined), label: 'Create'),
    NavigationDestination(icon: Icon(Icons.center_focus_strong), label: 'Scan'),
    NavigationDestination(icon: Icon(Icons.history_rounded), label: 'History'),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final content = IndexedStack(index: index, children: pages);
    return Scaffold(
      body: SafeArea(
        child: wide
            ? Row(children: [
                Container(
                  width: 224,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      right: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                  ),
                  child: Column(children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 30),
                      child: Align(alignment: Alignment.centerLeft, child: BrandMark()),
                    ),
                    Expanded(
                      child: NavigationRail(
                        extended: true,
                        selectedIndex: index,
                        onDestinationSelected: _navigate,
                        groupAlignment: -1,
                        destinations: destinations
                            .map((item) => NavigationRailDestination(
                                  icon: item.icon,
                                  label: Text(item.label),
                                ))
                            .toList(),
                      ),
                    ),
                    IconButton(
                      tooltip: widget.state.darkMode ? 'Use light theme' : 'Use dark theme',
                      onPressed: widget.state.toggleTheme,
                      icon: Icon(widget.state.darkMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined),
                    ),
                    const SizedBox(height: 20),
                  ]),
                ),
                Expanded(child: content),
              ])
            : content,
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: _navigate,
              destinations: destinations,
            ),
    );
  }
}

