import '../models/ai_wallet_models.dart';

abstract interface class AiWalletRepository {
  Future<AiWalletData> fetchWallet();
  Future<AiCreditPurchaseRequest> requestPurchase(AiCreditPurchaseInput input);
}
