import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/finance/models/finance_models.dart';
import 'package:siteseva/features/sites/models/site_models.dart';

void main() {
  group('Finance models', () {
    test('parses exact PaymentOut and ExpenseOut contracts', () {
      final payment = PaymentRecord.fromJson(_paymentPayload);
      final expense = ExpenseRecord.fromJson(_expensePayload);

      expect(payment.id, 'payment-1');
      expect(payment.type, PaymentType.clientReceived);
      expect(payment.amount, 250000);
      expect(payment.hasAttachment, isTrue);
      expect(expense.category, ExpenseCategory.fuel);
      expect(expense.paidBy, 'Ravi Kumar');
      expect(expense.hasReceipt, isTrue);
    });

    test('serializes exact PaymentIn payload without empty optionals', () {
      final brief = PaymentBrief.initial(referenceDate: DateTime(2026, 8, 7))
          .copyWith(
            siteId: 'site-1',
            type: PaymentType.material,
            amount: 54000,
            description: 'Cement milestone payment',
          );

      expect(brief.validationMessage(DateTime(2026, 8, 7)), isNull);
      expect(brief.toApiJson(), {
        'site_id': 'site-1',
        'type': 'MATERIAL',
        'amount': 54000,
        'description': 'Cement milestone payment',
        'date': '2026-08-07',
      });
    });

    test('validates future dates, non-positive amounts, and insecure URLs', () {
      final reference = DateTime(2026, 8, 7);
      final payment = PaymentBrief.initial(referenceDate: reference).copyWith(
        siteId: 'site-1',
        amount: 1,
        description: 'Valid record',
        date: DateTime(2026, 8, 8),
      );
      final expense = ExpenseBrief.initial(referenceDate: reference).copyWith(
        siteId: 'site-1',
        amount: 200,
        description: 'Fuel refill',
        receiptUrl: 'http://insecure.test/receipt.jpg',
      );

      expect(payment.validationMessage(reference), contains('future'));
      expect(expense.validationMessage(reference), contains('HTTPS'));
      expect(
        expense
            .copyWith(receiptUrl: '', amount: 0)
            .validationMessage(reference),
        contains('greater than zero'),
      );
    });

    test('does not double count expense rows mirrored into payments', () {
      final data = _studio(
        audience: FinanceAudience.contractor,
        payments: [
          PaymentRecord.fromJson(_paymentPayload),
          PaymentRecord.fromJson({
            ..._paymentPayload,
            'id': 'payment-expense-1',
            'type': 'EXPENSE',
            'amount': 4200,
          }),
        ],
        expenses: [ExpenseRecord.fromJson(_expensePayload)],
      );

      expect(data.recordedInflow, 250000);
      expect(data.recordedOutflow, 4200);
      expect(data.netRecordedCashflow, 245800);
    });

    test('filters payment ledger by site, type, period, and query', () {
      final older = PaymentRecord.fromJson({
        ..._paymentPayload,
        'id': 'payment-older',
        'site_id': 'site-2',
        'type': 'MATERIAL',
        'date': '2026-04-01',
        'description': 'Steel purchase',
      });
      final data =
          _studio(
            audience: FinanceAudience.contractor,
            payments: [PaymentRecord.fromJson(_paymentPayload), older],
          ).copyWith(
            siteFilter: 'site-1',
            paymentTypeFilter: PaymentType.clientReceived,
            query: 'orchid',
          );

      expect(data.visiblePayments.map((item) => item.id), ['payment-1']);
    });

    test('derives expense mix and trend only from filtered server records', () {
      final data = _studio(
        audience: FinanceAudience.supervisor,
        expenses: [
          ExpenseRecord.fromJson(_expensePayload),
          ExpenseRecord.fromJson({
            ..._expensePayload,
            'id': 'expense-2',
            'category': 'TRANSPORT',
            'amount': 1200,
          }),
        ],
      );

      expect(data.visibleCategorySummary.length, 2);
      expect(data.visibleCategorySummary.first.total, 4200);
      expect(data.recordedOutflow, 5400);
      expect(
        data.trend.fold<double>(0, (sum, item) => sum + item.outflow),
        5400,
      );
    });

    test('parses backend expense report without inventing categories', () {
      final report = ExpenseReport.fromJson({
        'by_category': [
          {'_id': 'FUEL', 'total': 4200, 'count': 1},
        ],
        'monthly': [
          {'_id': '2026-08', 'total': 4200},
        ],
      });

      expect(report.byCategory.single.category, ExpenseCategory.fuel);
      expect(report.monthly.single.month, '2026-08');
      expect(report.monthly.single.total, 4200);
    });
  });
}

FinanceStudioData _studio({
  required FinanceAudience audience,
  List<PaymentRecord> payments = const [],
  List<ExpenseRecord> expenses = const [],
}) => FinanceStudioData(
  payments: payments,
  expenses: expenses,
  expenseReport: ExpenseReport.empty(),
  sites: [_site, _secondSite],
  audience: audience,
  fetchedAt: DateTime(2026, 8, 7, 12),
  referenceDate: DateTime(2026, 8, 7),
);

final _site = SiteSummary.fromJson({
  'id': 'site-1',
  'name': 'Orchid Residence',
  'location': 'Gurugram',
  'status': 'ACTIVE',
  'progress': 64,
});

final _secondSite = SiteSummary.fromJson({
  'id': 'site-2',
  'name': 'Azure Offices',
  'location': 'Noida',
  'status': 'ACTIVE',
  'progress': 35,
});

const _paymentPayload = <String, dynamic>{
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
};

const _expensePayload = <String, dynamic>{
  'id': 'expense-1',
  'company_id': 'company-1',
  'site_id': 'site-1',
  'category': 'FUEL',
  'amount': 4200,
  'description': 'Excavator diesel refill',
  'paid_by': 'Ravi Kumar',
  'receipt_url': 'https://res.cloudinary.com/site/receipt.jpg',
  'date': '2026-08-07',
  'created_by': 'supervisor-1',
  'created_at': '2026-08-07T10:00:00Z',
};
