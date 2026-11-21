import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import 'admin_screen.dart';
import 'dashboard_screen.dart';
import 'operations_screen.dart';
import 'profile_screen.dart';
import 'sites_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.controller.role == 'SUPER_ADMIN';
    final destinations = isAdmin
        ? const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_rounded),
              label: 'Admin',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.apartment_rounded),
              label: 'Sites',
            ),
            NavigationDestination(
              icon: Icon(Icons.widgets_rounded),
              label: 'Operations',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ];
    final pages = isAdmin
        ? <Widget>[
            DashboardScreen(
              api: widget.controller.api,
              role: widget.controller.role,
              user: widget.controller.user!,
            ),
            AdminScreen(api: widget.controller.api),
            ProfileScreen(controller: widget.controller),
          ]
        : <Widget>[
            DashboardScreen(
              api: widget.controller.api,
              role: widget.controller.role,
              user: widget.controller.user!,
            ),
            SitesScreen(
              api: widget.controller.api,
              canCreate: widget.controller.role == 'CONTRACTOR',
            ),
            OperationsScreen(
              api: widget.controller.api,
              role: widget.controller.role,
            ),
            ProfileScreen(controller: widget.controller),
          ];
    final titles = isAdmin
        ? const ['Admin dashboard', 'Platform control', 'Profile']
        : const ['Dashboard', 'Sites', 'Operations', 'Profile'];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.construction_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(titles[_index])),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh account',
            onPressed: widget.controller.refreshUser,
            icon: const Icon(Icons.sync_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: destinations,
      ),
    );
  }
}
