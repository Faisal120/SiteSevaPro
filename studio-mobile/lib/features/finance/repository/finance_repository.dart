import '../../../core/media/app_image_picker.dart';
import '../models/finance_models.dart';

abstract interface class FinanceRepository {
  Future<FinanceStudioData> fetchStudio();
  Future<PaymentRecord> createPayment(PaymentBrief brief);
  Future<ExpenseRecord> createExpense(ExpenseBrief brief);
  Future<String> uploadAttachment(AppImageAsset asset);
}
