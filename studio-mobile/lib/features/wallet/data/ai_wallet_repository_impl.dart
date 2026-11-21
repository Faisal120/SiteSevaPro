import '../../../core/network/api_service.dart';
import '../../auth/models/auth_user.dart';
import '../models/ai_wallet_models.dart';
import '../repository/ai_wallet_repository.dart';
import 'ai_wallet_cache.dart';
import 'ai_wallet_remote_data_source.dart';

class AiWalletRepositoryImpl implements AiWalletRepository {
  const AiWalletRepositoryImpl({
    required AiWalletRemoteDataSource remote,
    required AiWalletCache cache,
    required AuthUser? user,
  }) : _remote = remote,
       _cache = cache,
       _user = user;

  final AiWalletRemoteDataSource _remote;
  final AiWalletCache _cache;
  final AuthUser? _user;

  @override
  Future<AiWalletData> fetchWallet() async {
    final user = _requireUser();
    if (!_canManage(user)) return AiWalletData.restricted(user);
    try {
      final results = await Future.wait<Object>([
        _remote.fetchWallet(),
        _remote.fetchTransactions(),
        _remote.fetchPurchaseConfig(),
        _remote.fetchPurchases(),
      ]);
      final payload = <String, dynamic>{
        'wallet': results[0],
        'transactions': results[1],
        'purchase_config': results[2],
        'purchases': results[3],
      };
      await _cache.write(user.id, payload);
      return _parse(user, payload, DateTime.now());
    } on ApiException catch (error) {
      if (!error.isConnectivityFailure) rethrow;
      final cached = await _cache.read(user.id);
      if (cached == null) rethrow;
      return _parse(user, cached.payload, cached.cachedAt, isOffline: true);
    }
  }

  @override
  Future<AiCreditPurchaseRequest> requestPurchase(
    AiCreditPurchaseInput input,
  ) async {
    final user = _requireUser();
    _guardManage(user);
    final validation = input.validationMessage;
    if (validation != null) {
      throw ApiException(validation, kind: ApiErrorKind.invalidResponse);
    }
    return AiCreditPurchaseRequest.fromJson(
      await _remote.requestPurchase(input.toJson()),
    );
  }

  AiWalletData _parse(
    AuthUser user,
    Map<String, dynamic> payload,
    DateTime fetchedAt, {
    bool isOffline = false,
  }) => AiWalletData(
    user: user,
    wallet: payload['wallet'] is Map
        ? AiCreditWallet.fromJson(_map(payload['wallet']))
        : null,
    transactions: maps(payload['transactions'])
        .map(AiCreditTransaction.fromJson)
        .toList(growable: false),
    purchaseConfig: payload['purchase_config'] is Map
        ? AiCreditPurchaseConfig.fromJson(_map(payload['purchase_config']))
        : null,
    purchases: maps(payload['purchases'])
        .map(AiCreditPurchaseRequest.fromJson)
        .toList(growable: false),
    fetchedAt: fetchedAt,
    isOffline: isOffline,
  );

  AuthUser _requireUser() {
    if (_user != null) return _user;
    throw const ApiException(
      'Sign in again to access AI credits.',
      statusCode: 401,
      kind: ApiErrorKind.authentication,
    );
  }

  bool _canManage(AuthUser user) => user.isContractor || user.isSuperAdmin;

  void _guardManage(AuthUser user) {
    if (_canManage(user)) return;
    throw const ApiException(
      'Only contractors can manage AI credit purchases.',
      statusCode: 403,
      kind: ApiErrorKind.authentication,
    );
  }
}

Map<String, dynamic> _map(Object? value) => value is Map
    ? value.map((key, item) => MapEntry('$key', item))
    : <String, dynamic>{};
