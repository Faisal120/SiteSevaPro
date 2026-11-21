import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_ui.dart';

class DashboardShell extends ConsumerWidget {
  const DashboardShell({super.key, required this.child});
  final Widget child;

  static const _destinations = [
    ('/', 'Home', Icons.grid_view_rounded, Icons.grid_view_rounded),
    ('/sites', 'Sites', Icons.apartment_outlined, Icons.apartment_rounded),
    (
      '/design-studio',
      'AI Studio',
      Icons.auto_awesome_outlined,
      Icons.auto_awesome_rounded,
    ),
    (
      '/materials',
      'Stock',
      Icons.inventory_2_outlined,
      Icons.inventory_2_rounded,
    ),
    (
      '/settings',
      'Profile',
      Icons.person_outline_rounded,
      Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final session = ref.watch(authControllerProvider).valueOrNull;
    final destinations = _roleDestinations(session);
    final index = destinations
        .indexWhere(
          (destination) =>
              location == destination.$1 ||
              (destination.$1 != '/' && location.startsWith(destination.$1)),
        )
        .clamp(0, destinations.length - 1);
    final router = GoRouter.of(context);
    return PopScope<void>(
      canPop: router.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        // A direct deep link has no prior route. In that one case, home is the
        // safe fallback; normal system back preserves the user's history.
        if (!didPop && location != '/') context.go('/');
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 840;
          return Scaffold(
            body: wide
                ? Row(
                    children: [
                      _SideRail(
                        destinations: destinations,
                        selectedIndex: index,
                        session: session,
                        onSelected: (value) =>
                            context.go(destinations[value].$1),
                      ),
                      Expanded(child: child),
                    ],
                  )
                : child,
            floatingActionButton: location == '/assistant'
                ? null
                : FloatingActionButton.extended(
                    heroTag: 'site-seva-ai-fab',
                    onPressed: () => context.go('/assistant'),
                    backgroundColor: AppTheme.blue,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('AI'),
                  ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endFloat,
            bottomNavigationBar: wide
                ? null
                : _PremiumBottomNavigation(
                    destinations: destinations,
                    selectedIndex: index,
                    onSelected: (value) =>
                        context.go(destinations[value].$1),
                  ),
          );
        },
      ),
    );
  }

  List<(String, String, IconData, IconData)> _roleDestinations(
    UserSession? session,
  ) {
    if (session?.isSupervisor ?? false) {
      return const [
        ('/', 'Home', Icons.grid_view_rounded, Icons.grid_view_rounded),
        ('/sites', 'Sites', Icons.apartment_outlined, Icons.apartment_rounded),
        (
          '/design-studio',
          'AI Studio',
          Icons.auto_awesome_outlined,
          Icons.auto_awesome_rounded,
        ),
        (
          '/materials',
          'Stock',
          Icons.inventory_2_outlined,
          Icons.inventory_2_rounded,
        ),
        (
          '/settings',
          'Profile',
          Icons.person_outline_rounded,
          Icons.person_rounded,
        ),
      ];
    }
    if (session?.isClient ?? false) {
      return const [
        ('/', 'Home', Icons.grid_view_rounded, Icons.grid_view_rounded),
        (
          '/sites',
          'Project',
          Icons.apartment_outlined,
          Icons.apartment_rounded,
        ),
        (
          '/design-studio',
          'AI Studio',
          Icons.auto_awesome_outlined,
          Icons.auto_awesome_rounded,
        ),
        (
          '/payments',
          'Payments',
          Icons.payments_outlined,
          Icons.payments_rounded,
        ),
        (
          '/settings',
          'Profile',
          Icons.person_outline_rounded,
          Icons.person_rounded,
        ),
      ];
    }
    return _destinations;
  }
}

class _PremiumBottomNavigation extends StatelessWidget {
  const _PremiumBottomNavigation({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<(String, String, IconData, IconData)> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? const Color(0xFF0D1421) : Colors.white,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: dark ? const Color(0xFF263147) : AppTheme.line,
              ),
            ),
          ),
          child: Row(
            children: destinations.indexed.map((entry) {
              final index = entry.$1;
              final destination = entry.$2;
              final selected = index == selectedIndex;
              final isStudio = index == 2;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelected(index),
                  child: isStudio
                      ? Transform.translate(
                          offset: const Offset(0, -12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                width: selected ? 58 : 54,
                                height: selected ? 58 : 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.orange,
                                  border: Border.all(
                                    color: dark
                                        ? const Color(0xFF0D1421)
                                        : Colors.white,
                                    width: 5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x45F36B21),
                                      blurRadius: 18,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  selected ? destination.$4 : destination.$3,
                                  color: Colors.white,
                                  size: 23,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                destination.$2,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: selected
                                          ? AppTheme.orange
                                          : AppTheme.muted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTheme.orange.withValues(alpha: .1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                selected ? destination.$4 : destination.$3,
                                color: selected
                                    ? AppTheme.orange
                                    : AppTheme.muted,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              destination.$2,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: selected
                                        ? AppTheme.orange
                                        : AppTheme.muted,
                                    fontSize: 9,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.destinations,
    required this.selectedIndex,
    required this.session,
    required this.onSelected,
  });
  final List<(String, String, IconData, IconData)> destinations;
  final int selectedIndex;
  final UserSession? session;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    width: 232,
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 22),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0D1421)
          : Colors.white,
      border: Border(
        right: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF263147)
              : AppTheme.line,
        ),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(left: 6), child: AppLogo()),
        const SizedBox(height: 38),
        Text(
          'WORKSPACE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.muted,
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 10),
        ...destinations.indexed.map((entry) {
          final destination = entry.$2;
          final selected = entry.$1 == selectedIndex;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: selected
                  ? AppTheme.orange.withValues(alpha: .11)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => onSelected(entry.$1),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected ? destination.$4 : destination.$3,
                        color: selected ? AppTheme.orange : AppTheme.muted,
                        size: 19,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        destination.$2,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: selected ? AppTheme.orange : null,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        SurfaceCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppTheme.navy,
                child: Text(
                  (session?.name.trim().isNotEmpty == true
                          ? session!.name.trim()[0]
                          : 'S')
                      .toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session?.name ?? 'SiteSeva user',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      session?.roleLabel ?? 'Workspace',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
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
