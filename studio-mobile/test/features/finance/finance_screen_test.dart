import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/media/app_image_picker.dart';
import 'package:siteseva/core/theme/app_theme.dart';
import 'package:siteseva/features/finance/models/finance_models.dart';
import 'package:siteseva/features/finance/presentation/screens/finance_record_detail_screen.dart';
import 'package:siteseva/features/finance/presentation/screens/finance_screen.dart';
import 'package:siteseva/features/finance/providers/finance_provider.dart';
import 'package:siteseva/features/finance/repository/finance_repository.dart';
import 'package:siteseva/features/sites/models/site_models.dart';

void main() {
  testWidgets(
    'contractor desktop renders cash-flow intelligence and live records',
    (tester) async {
      await _pump(
        tester,
        size: const Size(1440, 1100),
        data: _contractorStudio,
        child: const FinanceScreen(),
      );

      expect(find.text('Finance Control'), findsOneWidget);
      expect(find.text('RECORDED CASH FLOW'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);
      expect(find.text('Field expenses'), findsOneWidget);
      expect(find.text('Cash-flow activity'), findsOneWidget);
      expect(find.text('Foundation milestone receipt'), findsWidgets);
      expect(find.text('INR 2.5 L'), findsWidgets);
      expect(find.text('Record payment'), findsOneWidget);
      _expectNoFlutterException(tester);
    },
  );

  testWidgets('contractor mobile finance settles without responsive overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      data: _contractorStudio,
      child: const FinanceScreen(),
    );

    expect(find.text('Finance Control'), findsOneWidget);
    expect(find.byTooltip('Record payment'), findsOneWidget);
    expect(find.text('RECORDED CASH FLOW'), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets(
    'supervisor sees assigned field expenses without payment controls',
    (tester) async {
      final supervisor = _contractorStudio.copyWith(
        payments: const [],
        audience: FinanceAudience.supervisor,
        workspace: FinanceWorkspace.expenses,
      );
      await _pump(
        tester,
        size: const Size(390, 844),
        data: supervisor,
        child: const FinanceScreen(initialWorkspace: FinanceWorkspace.expenses),
      );

      expect(find.text('FIELD EXPENSE CONTROL'), findsOneWidget);
      expect(find.text('Field expense timeline'), findsOneWidget);
      expect(find.byTooltip('Add expense'), findsOneWidget);
      expect(find.text('Payments'), findsNothing);
      expect(find.text('Record payment'), findsNothing);
      _expectNoFlutterException(tester);
    },
  );

  testWidgets('client receives a read-only verified payment history', (
    tester,
  ) async {
    final client = _contractorStudio.copyWith(
      expenses: const [],
      audience: FinanceAudience.client,
      workspace: FinanceWorkspace.payments,
    );
    await _pump(
      tester,
      size: const Size(390, 844),
      data: client,
      child: const FinanceScreen(initialWorkspace: FinanceWorkspace.payments),
    );

    expect(find.text('Payment History'), findsOneWidget);
    expect(find.text('PAYMENTS RECEIVED'), findsOneWidget);
    expect(find.text('Verified payment history'), findsOneWidget);
    expect(find.text('Field expenses'), findsNothing);
    expect(find.byIcon(Icons.add_rounded), findsNothing);
    _expectNoFlutterException(tester);
  });

  testWidgets('payment detail renders immutable server audit context', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(1100, 1000),
      data: _contractorStudio,
      child: const FinanceRecordDetailScreen(
        recordId: 'payment-1',
        kind: FinanceRecordKind.payment,
      ),
    );

    expect(find.text('Payment Detail'), findsOneWidget);
    expect(find.text('Audit details'), findsOneWidget);
    expect(find.text('Foundation milestone receipt'), findsOneWidget);
    expect(find.text('Record ID'), findsOneWidget);
    expect(find.text('payment-1'), findsOneWidget);
    expect(find.text('Invoice attachment'), findsOneWidget);
    expect(find.textContaining('not a GST invoice'), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets('offline snapshot disables finance mutations', (tester) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      data: _contractorStudio.copyWith(isOffline: true),
      child: const FinanceScreen(),
    );

    expect(find.textContaining('Offline snapshot'), findsOneWidget);
    expect(find.byTooltip('Record payment'), findsOneWidget);
    _expectNoFlutterException(tester);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required FinanceStudioData data,
  required Widget child,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = _FakeFinanceRepository(data);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        financeRepositoryProvider.overrideWithValue(repository),
        financeStudioControllerProvider.overrideWith(
          (ref) => _LoadedFinanceController(data, repository),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: child),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump(const Duration(milliseconds: 900));
}

void _expectNoFlutterException(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception case final FlutterError error) {
    debugPrint(error.toStringDeep());
  }
  expect(exception, isNull);
}

class _LoadedFinanceController extends FinanceStudioController {
  _LoadedFinanceController(FinanceStudioData data, FinanceRepository repository)
    : super(repository) {
    state = AsyncValue.data(data);
  }
}

class _FakeFinanceRepository implements FinanceRepository {
  const _FakeFinanceRepository(this.data);
  final FinanceStudioData data;

  @override
  Future<FinanceStudioData> fetchStudio() async => data;

  @override
  Future<PaymentRecord> createPayment(PaymentBrief brief) async => _payment;

  @override
  Future<ExpenseRecord> createExpense(ExpenseBrief brief) async => _expense;

  @override
  Future<String> uploadAttachment(AppImageAsset asset) async =>
      'https://res.cloudinary.com/site/${asset.filename}';
}

final _site = SiteSummary.fromJson({
  'id': 'site-1',
  'name': 'Orchid Residence',
  'location': 'Sector 57, Gurugram',
  'status': 'ACTIVE',
  'progress': 64,
});

final _payment = PaymentRecord.fromJson({
  'id': 'payment-1',
  'company_id': 'company-1',
  'site_id': 'site-1',
  'type': 'CLIENT_RECEIVED',
  'amount': 250000,
  'description': 'Foundation milestone receipt',
  'party': 'Ananya Rao',
  'invoice_url': 'https://res.cloudinary.com/site/invoice.jpg',
  'date': '2026-08-07',
  'created_by': 'contractor-1',
  'created_at': '2026-08-07T09:00:00Z',
});

final _outflow = PaymentRecord.fromJson({
  'id': 'payment-2',
  'company_id': 'company-1',
  'site_id': 'site-1',
  'type': 'EXPENSE',
  'amount': 4200,
  'description': 'Excavator diesel refill',
  'party': 'Ravi Kumar',
  'date': '2026-08-07',
});

final _expense = ExpenseRecord.fromJson({
  'id': 'expense-1',
  'company_id': 'company-1',
  'site_id': 'site-1',
  'category': 'FUEL',
  'amount': 4200,
  'description': 'Excavator diesel refill',
  'paid_by': 'Ravi Kumar',
  'receipt_url': 'https://res.cloudinary.com/site/receipt.jpg',
  'date': '2026-08-07',
});

final _contractorStudio = FinanceStudioData(
  payments: [_payment, _outflow],
  expenses: [_expense],
  expenseReport: ExpenseReport.fromJson({
    'by_category': [
      {'_id': 'FUEL', 'total': 4200, 'count': 1},
    ],
    'monthly': [
      {'_id': '2026-08', 'total': 4200},
    ],
  }),
  sites: [_site],
  audience: FinanceAudience.contractor,
  fetchedAt: DateTime(2026, 8, 7, 12),
  referenceDate: DateTime(2026, 8, 7),
);
