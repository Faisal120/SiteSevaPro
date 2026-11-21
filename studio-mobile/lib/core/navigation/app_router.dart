import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/models/auth_user.dart';
import '../../features/auth/presentation/screens/contractor_application_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/attendance/presentation/screens/payroll_screen.dart';
import '../../features/attendance/presentation/screens/workforce_detail_screen.dart';
import '../../features/attendance/presentation/screens/workforce_screen.dart';
import '../../features/assistant/presentation/screens/assistant_screen.dart';
import '../../features/boq/presentation/screens/boq_detail_screen.dart';
import '../../features/boq/presentation/screens/boq_screen.dart';
import '../../features/crm/presentation/screens/crm_screen.dart';
import '../../features/dashboard/dashboard_shell.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/design_studio/presentation/screens/design_studio_screen.dart';
import '../../features/design_studio/presentation/screens/design_viewer_screen.dart';
import '../../features/documents/presentation/screens/document_center_screen.dart';
import '../../features/estimate/presentation/screens/estimate_detail_screen.dart';
import '../../features/estimate/presentation/screens/estimate_screen.dart';
import '../../features/finance/models/finance_models.dart';
import '../../features/finance/presentation/screens/finance_record_detail_screen.dart';
import '../../features/finance/presentation/screens/finance_screen.dart';
import '../../features/materials/presentation/screens/material_detail_screen.dart';
import '../../features/materials/presentation/screens/materials_screen.dart';
import '../../features/modules/module_pages.dart';
import '../../features/notifications/presentation/screens/notification_detail_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_company_screen.dart';
import '../../features/profile/presentation/widgets/profile_company_widgets.dart';
import '../../features/planning/presentation/screens/planning_screen.dart';
import '../../features/reports/presentation/screens/report_detail_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/models/settings_models.dart';
import '../../features/settings/presentation/screens/settings_security_screen.dart';
import '../../features/sites/presentation/screens/site_detail_screen.dart';
import '../../features/sites/presentation/screens/sites_screen.dart';
import '../../features/wallet/presentation/screens/ai_wallet_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authController = ref.read(authControllerProvider.notifier);
  final refresh = _RouterRefresh(authController.stream);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _page(
          state: state,
          child: const SplashScreen(),
          transition: _RouteTransition.fade,
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _page(
          state: state,
          child: const LoginScreen(),
          transition: _RouteTransition.fadeSlide,
        ),
      ),
      GoRoute(
        path: '/apply',
        pageBuilder: (context, state) => _page(
          state: state,
          child: const ContractorApplicationScreen(),
          transition: _RouteTransition.cupertino,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/sites',
            builder: (context, state) => const SitesScreen(),
          ),
          GoRoute(
            path: '/sites/:siteId',
            builder: (context, state) =>
                SiteDetailScreen(siteId: state.pathParameters['siteId']!),
          ),
          GoRoute(
            path: '/labour',
            builder: (context, state) => const WorkforceScreen(),
          ),
          GoRoute(
            path: '/attendance',
            builder: (context, state) => const AttendanceScreen(),
          ),
          GoRoute(
            path: '/labour/wallet',
            builder: (context, state) => const PayrollScreen(),
          ),
          GoRoute(
            path: '/labour/:labourId',
            pageBuilder: (context, state) => _page(
              state: state,
              child: WorkforceDetailScreen(
                labourId: state.pathParameters['labourId']!,
              ),
              transition: _RouteTransition.fadeSlide,
            ),
          ),
          GoRoute(
            path: '/materials',
            builder: (context, state) => const MaterialsScreen(),
          ),
          GoRoute(
            path: '/materials/:materialId',
            pageBuilder: (context, state) => _page(
              state: state,
              child: MaterialDetailScreen(
                materialId: state.pathParameters['materialId']!,
              ),
              transition: _RouteTransition.fadeSlide,
            ),
          ),
          GoRoute(
            path: '/vendors',
            builder: (context, state) => const VendorsPage(),
          ),
          GoRoute(
            path: '/crm',
            builder: (context, state) => const CrmScreen(),
          ),
          GoRoute(
            path: '/documents',
            builder: (context, state) => const DocumentCenterScreen(),
          ),
          GoRoute(
            path: '/payments',
            builder: (context, state) => FinanceScreen(
              initialWorkspace: FinanceWorkspace.payments,
              initialSiteId: state.uri.queryParameters['siteId'],
            ),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => FinanceScreen(
              initialWorkspace: FinanceWorkspace.expenses,
              initialSiteId: state.uri.queryParameters['siteId'],
            ),
          ),
          GoRoute(
            path: '/payments/:paymentId',
            pageBuilder: (context, state) => _page(
              state: state,
              child: FinanceRecordDetailScreen(
                recordId: state.pathParameters['paymentId']!,
                kind: FinanceRecordKind.payment,
              ),
              transition: _RouteTransition.fadeSlide,
            ),
          ),
          GoRoute(
            path: '/expenses/:expenseId',
            pageBuilder: (context, state) => _page(
              state: state,
              child: FinanceRecordDetailScreen(
                recordId: state.pathParameters['expenseId']!,
                kind: FinanceRecordKind.expense,
              ),
              transition: _RouteTransition.fadeSlide,
            ),
          ),
          GoRoute(
            path: '/estimates',
            builder: (context, state) => const EstimateScreen(),
          ),
          GoRoute(
            path: '/estimates/:estimateId',
            pageBuilder: (context, state) => _page(
              state: state,
              child: EstimateDetailScreen(
                estimateId: state.pathParameters['estimateId']!,
              ),
              transition: _RouteTransition.fadeSlide,
            ),
          ),
          GoRoute(path: '/boq', builder: (context, state) => const BoqScreen()),
          GoRoute(
            path: '/boq/:boqId',
            pageBuilder: (context, state) => _page(
              state: state,
              child: BoqDetailScreen(boqId: state.pathParameters['boqId']!),
              transition: _RouteTransition.fadeSlide,
            ),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => ReportsScreen(
              initialSiteId: state.uri.queryParameters['siteId'],
            ),
          ),
          GoRoute(
            path: '/reports/:reportId',
            pageBuilder: (context, state) => _page(
              state: state,
              child: ReportDetailScreen(
                reportId: state.pathParameters['reportId']!,
              ),
              transition: _RouteTransition.fadeSlide,
            ),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/assistant',
            builder: (context, state) => const AssistantScreen(),
          ),
          GoRoute(
            path: '/planning',
            builder: (context, state) => const PlanningScreen(),
          ),
          GoRoute(
            path: '/notifications/:notificationId',
            pageBuilder: (context, state) => _page(
              state: state,
              child: NotificationDetailScreen(
                notificationId: state.pathParameters['notificationId']!,
              ),
              transition: _RouteTransition.fadeSlide,
            ),
          ),
          GoRoute(
            path: '/subscription',
            builder: (context, state) => const SettingsSecurityScreen(
              initialTab: SettingsTab.subscription,
            ),
          ),
          GoRoute(
            path: '/branding',
            builder: (context, state) => const ProfileCompanyScreen(
              initialTab: ProfileCompanyTab.company,
            ),
          ),
          GoRoute(
            path: '/design-studio',
            builder: (context, state) => const DesignStudioScreen(),
          ),
          GoRoute(
            path: '/design-studio/design/:designId',
            pageBuilder: (context, state) => _page(
              state: state,
              child: DesignViewerScreen(
                designId: state.pathParameters['designId']!,
              ),
              transition: _RouteTransition.fadeSlide,
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const ProfileCompanyScreen(),
          ),
          GoRoute(
            path: '/preferences',
            builder: (context, state) => const SettingsSecurityScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileCompanyScreen(),
          ),
          GoRoute(
            path: '/help',
            builder: (context, state) => const HelpCenterPage(),
          ),
          GoRoute(
            path: '/security',
            builder: (context, state) => const SettingsSecurityScreen(
              initialTab: SettingsTab.security,
            ),
          ),
          GoRoute(
            path: '/wallet',
            builder: (context, state) => const AiWalletScreen(),
          ),
        ],
      ),
    ],
  );
});

String? _redirect(Ref ref, GoRouterState state) {
  final auth = ref.read(authControllerProvider);
  final path = state.uri.path;
  final isPublic = path == '/login' || path == '/apply';

  if (auth.isLoading) return path == '/splash' ? null : '/splash';

  final user = auth.valueOrNull;
  if (user == null) {
    if (isPublic) return null;
    if (path == '/splash') return '/login';
    final destination = Uri.encodeComponent(state.uri.toString());
    return '/login?redirect=$destination';
  }

  if (path == '/splash' || isPublic) {
    final destination = state.uri.queryParameters['redirect'];
    if (path == '/login' &&
        destination != null &&
        destination.startsWith('/')) {
      return destination;
    }
    return '/';
  }

  if (!_canOpen(user, path)) return '/';
  return null;
}

bool _canOpen(AuthUser user, String path) {
  if (user.isContractor || user.isSuperAdmin) return true;
  if (path == '/payments' || path.startsWith('/payments/')) {
    return user.isClient;
  }
  if (path == '/expenses' || path.startsWith('/expenses/')) {
    return user.isSupervisor;
  }
  if (path == '/labour/wallet') return false;
  if (path == '/labour' || path.startsWith('/labour/')) {
    return user.isSupervisor;
  }
  if (path == '/materials' || path.startsWith('/materials/')) {
    return user.isSupervisor;
  }
  const contractorOnly = {
    '/vendors',
    '/estimates',
    '/boq',
    '/subscription',
    '/wallet',
    '/branding',
  };
  return !contractorOnly.any(
    (restrictedPath) =>
        path == restrictedPath || path.startsWith('$restrictedPath/'),
  );
}

enum _RouteTransition { fade, fadeSlide, cupertino }

Page<void> _page({
  required GoRouterState state,
  required Widget child,
  required _RouteTransition transition,
}) => CustomTransitionPage<void>(
  key: state.pageKey,
  child: child,
  transitionDuration: const Duration(milliseconds: 420),
  reverseTransitionDuration: const Duration(milliseconds: 330),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    if (transition == _RouteTransition.fade) {
      return FadeTransition(opacity: curve, child: child);
    }
    final begin = transition == _RouteTransition.cupertino
        ? const Offset(1, 0)
        : const Offset(0, .025);
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curve),
        child: child,
      ),
    );
  },
);

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
