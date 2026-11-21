import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/workforce_cache.dart';
import '../data/workforce_remote_data_source.dart';
import '../data/workforce_repository_impl.dart';
import '../models/attendance_models.dart';
import '../models/workforce_models.dart';
import '../repository/workforce_repository.dart';

final workforceRemoteDataSourceProvider = Provider<WorkforceRemoteDataSource>(
  (ref) => const HttpWorkforceRemoteDataSource(),
);

final workforceCacheProvider = Provider<WorkforceCache>(
  (ref) => HiveWorkforceCache(),
);

final workforceRepositoryProvider = Provider<WorkforceRepository>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  return WorkforceRepositoryImpl(
    remote: ref.watch(workforceRemoteDataSourceProvider),
    cache: ref.watch(workforceCacheProvider),
    userId: user?.id ?? '',
    canViewAttendance:
        user?.isContractor == true ||
        user?.isSupervisor == true ||
        user?.isClient == true,
    canEditAttendance: user?.isContractor == true || user?.isSupervisor == true,
    canViewMembers: user?.isContractor == true || user?.isSupervisor == true,
    canManageMembers: user?.isContractor == true,
    canViewWallet: user?.isContractor == true || user?.isSupervisor == true,
    canManageWallet: user?.isContractor == true,
  );
});

final attendanceBoardControllerProvider =
    StateNotifierProvider<
      AttendanceBoardController,
      AsyncValue<AttendanceBoardData>
    >((ref) {
      final controller = AttendanceBoardController(
        ref.watch(workforceRepositoryProvider),
      );
      unawaited(controller.load());
      return controller;
    });

final attendanceActionControllerProvider =
    StateNotifierProvider.autoDispose<
      AttendanceActionController,
      AsyncValue<AttendanceDocument?>
    >((ref) {
      return AttendanceActionController(
        repository: ref.watch(workforceRepositoryProvider),
        onSaved: () =>
            ref.read(attendanceBoardControllerProvider.notifier).refresh(),
      );
    });

final workforceStudioControllerProvider =
    StateNotifierProvider<
      WorkforceStudioController,
      AsyncValue<WorkforceStudioData>
    >((ref) {
      final controller = WorkforceStudioController(
        ref.watch(workforceRepositoryProvider),
      );
      unawaited(controller.load());
      return controller;
    });

final workforceCreationBriefProvider =
    StateNotifierProvider.autoDispose<
      WorkforceCreationBriefController,
      WorkforceCreationBrief
    >((ref) => WorkforceCreationBriefController());

final workforceActionControllerProvider =
    StateNotifierProvider.autoDispose<
      WorkforceActionController,
      AsyncValue<WorkforceMember?>
    >((ref) {
      return WorkforceActionController(
        repository: ref.watch(workforceRepositoryProvider),
        onChanged: () async {
          await ref.read(workforceStudioControllerProvider.notifier).refresh();
          await ref.read(attendanceBoardControllerProvider.notifier).refresh();
        },
      );
    });

final workforceDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<WorkforceDetailController, AsyncValue<WorkforceDetail>, String>((
      ref,
      labourId,
    ) {
      final controller = WorkforceDetailController(
        repository: ref.watch(workforceRepositoryProvider),
        labourId: labourId,
      );
      unawaited(controller.load());
      return controller;
    });

final walletSettlementBriefProvider = StateNotifierProvider.autoDispose
    .family<WalletSettlementBriefController, WalletSettlementBrief, String>(
      (ref, labourId) => WalletSettlementBriefController(labourId),
    );

final walletActionControllerProvider =
    StateNotifierProvider.autoDispose<WalletActionController, AsyncValue<void>>(
      (ref) {
        return WalletActionController(
          repository: ref.watch(workforceRepositoryProvider),
          onSettled: (labourId) async {
            await ref
                .read(workforceDetailControllerProvider(labourId).notifier)
                .load();
            await ref
                .read(workforceStudioControllerProvider.notifier)
                .refresh();
          },
        );
      },
    );

final payrollControllerProvider =
    StateNotifierProvider<PayrollController, AsyncValue<PayrollData>>((ref) {
      final controller = PayrollController(
        ref.watch(workforceRepositoryProvider),
      );
      unawaited(controller.load(_currentMonth()));
      return controller;
    });

final payrollActionControllerProvider =
    StateNotifierProvider.autoDispose<
      PayrollActionController,
      AsyncValue<PayrollRecord?>
    >((ref) {
      return PayrollActionController(
        repository: ref.watch(workforceRepositoryProvider),
        onGenerated: (month) =>
            ref.read(payrollControllerProvider.notifier).load(month),
      );
    });

class AttendanceBoardController
    extends StateNotifier<AsyncValue<AttendanceBoardData>> {
  AttendanceBoardController(this._repository)
    : _date = attendanceApiDate(DateTime.now()),
      super(const AsyncValue.loading());

  final WorkforceRepository _repository;
  String? _siteId;
  String _date;

  String get selectedDate => _date;
  String? get selectedSiteId => _siteId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.fetchAttendance(siteId: _siteId, date: _date),
    );
    _siteId = state.valueOrNull?.siteId ?? _siteId;
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    try {
      final fresh = await _repository.fetchAttendance(
        siteId: _siteId,
        date: _date,
      );
      _siteId = fresh.siteId;
      state = AsyncValue.data(fresh);
    } catch (error, stackTrace) {
      if (previous == null) state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> selectSite(String siteId) async {
    if (siteId == _siteId) return;
    _siteId = siteId;
    await load();
  }

  Future<void> selectDate(DateTime date) async {
    final value = attendanceApiDate(date);
    if (value == _date) return;
    _date = value;
    await load();
  }

  void setStatus(String labourId, AttendanceStatus status) =>
      _updateDraft((draft) => draft.updateStatus(labourId, status));

  void setOvertime(String labourId, String value) => _updateDraft(
    (draft) =>
        draft.updateOvertime(labourId, double.tryParse(value.trim()) ?? 0),
  );

  void setAdvance(String labourId, String value) => _updateDraft(
    (draft) =>
        draft.updateAdvance(labourId, double.tryParse(value.trim()) ?? 0),
  );

  void markAll(AttendanceStatus status) =>
      _updateDraft((draft) => draft.markAll(status));

  void _updateDraft(AttendanceDraft Function(AttendanceDraft draft) update) {
    final data = state.valueOrNull;
    final draft = data?.draft;
    if (data == null || draft == null) return;
    state = AsyncValue.data(data.copyWith(draft: update(draft)));
  }
}

class AttendanceActionController
    extends StateNotifier<AsyncValue<AttendanceDocument?>> {
  AttendanceActionController({
    required WorkforceRepository repository,
    required Future<void> Function() onSaved,
  }) : _repository = repository,
       _onSaved = onSaved,
       super(const AsyncValue.data(null));

  final WorkforceRepository _repository;
  final Future<void> Function() _onSaved;

  Future<AttendanceDocument?> save(AttendanceDraft draft) async {
    state = const AsyncValue.loading();
    try {
      final document = await _repository.saveAttendance(draft);
      state = AsyncValue.data(document);
      await _onSaved();
      return document;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }
}

class WorkforceStudioController
    extends StateNotifier<AsyncValue<WorkforceStudioData>> {
  WorkforceStudioController(this._repository)
    : super(const AsyncValue.loading());

  final WorkforceRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.fetchWorkforce);
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    try {
      final fresh = await _repository.fetchWorkforce();
      state = AsyncValue.data(
        fresh.copyWith(
          query: previous?.query,
          siteFilter: previous?.siteFilter,
        ),
      );
    } catch (error, stackTrace) {
      if (previous == null) state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void setQuery(String value) {
    final data = state.valueOrNull;
    if (data != null) state = AsyncValue.data(data.copyWith(query: value));
  }

  void setSite(String? siteId) {
    final data = state.valueOrNull;
    if (data != null) {
      state = AsyncValue.data(
        data.copyWith(siteFilter: siteId, clearSite: siteId == null),
      );
    }
  }
}

class WorkforceCreationBriefController
    extends StateNotifier<WorkforceCreationBrief> {
  WorkforceCreationBriefController() : super(WorkforceCreationBrief.initial());

  void reset() => state = WorkforceCreationBrief.initial();
  void setName(String value) => state = state.copyWith(fullName: value);
  void setMobile(String value) => state = state.copyWith(mobile: value);
  void setTrade(String value) => state = state.copyWith(trade: value);
  void setWage(String value) =>
      state = state.copyWith(dailyWage: double.tryParse(value.trim()) ?? 0);
  void setSite(String value) => state = state.copyWith(siteId: value);
  void setAadhaar(String value) => state = state.copyWith(aadhaar: value);
  void setAddress(String value) => state = state.copyWith(address: value);
}

class WorkforceActionController
    extends StateNotifier<AsyncValue<WorkforceMember?>> {
  WorkforceActionController({
    required WorkforceRepository repository,
    required Future<void> Function() onChanged,
  }) : _repository = repository,
       _onChanged = onChanged,
       super(const AsyncValue.data(null));

  final WorkforceRepository _repository;
  final Future<void> Function() _onChanged;

  Future<WorkforceMember?> create(WorkforceCreationBrief brief) async {
    state = const AsyncValue.loading();
    try {
      final member = await _repository.createMember(brief);
      state = AsyncValue.data(member);
      await _onChanged();
      return member;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  Future<bool> delete(String labourId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteMember(labourId);
      state = const AsyncValue.data(null);
      await _onChanged();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}

class WorkforceDetailController
    extends StateNotifier<AsyncValue<WorkforceDetail>> {
  WorkforceDetailController({
    required WorkforceRepository repository,
    required this.labourId,
  }) : _repository = repository,
       super(const AsyncValue.loading());

  final WorkforceRepository _repository;
  final String labourId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchDetail(labourId));
  }
}

class WalletSettlementBriefController
    extends StateNotifier<WalletSettlementBrief> {
  WalletSettlementBriefController(String labourId)
    : super(WalletSettlementBrief.initial(labourId));

  void reset() => state = WalletSettlementBrief.initial(state.labourId);
  void setAmount(String value) =>
      state = state.copyWith(amount: double.tryParse(value.trim()) ?? 0);
  void setPaymentMode(LabourPaymentMode value) =>
      state = state.copyWith(paymentMode: value);
  void setRemarks(String value) => state = state.copyWith(remarks: value);
}

class WalletActionController extends StateNotifier<AsyncValue<void>> {
  WalletActionController({
    required WorkforceRepository repository,
    required Future<void> Function(String labourId) onSettled,
  }) : _repository = repository,
       _onSettled = onSettled,
       super(const AsyncValue.data(null));

  final WorkforceRepository _repository;
  final Future<void> Function(String labourId) _onSettled;

  Future<bool> settle(WalletSettlementBrief brief) async {
    state = const AsyncValue.loading();
    try {
      await _repository.settleWallet(brief);
      state = const AsyncValue.data(null);
      await _onSettled(brief.labourId);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}

class PayrollController extends StateNotifier<AsyncValue<PayrollData>> {
  PayrollController(this._repository) : super(const AsyncValue.loading());

  final WorkforceRepository _repository;
  String _month = _currentMonth();
  String get month => _month;

  Future<void> load(String month) async {
    _month = month;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchPayroll(month));
  }

  Future<void> refresh() => load(_month);
}

class PayrollActionController
    extends StateNotifier<AsyncValue<PayrollRecord?>> {
  PayrollActionController({
    required WorkforceRepository repository,
    required Future<void> Function(String month) onGenerated,
  }) : _repository = repository,
       _onGenerated = onGenerated,
       super(const AsyncValue.data(null));

  final WorkforceRepository _repository;
  final Future<void> Function(String month) _onGenerated;

  Future<PayrollRecord?> generate(String labourId, String month) async {
    state = const AsyncValue.loading();
    try {
      final payroll = await _repository.generatePayroll(labourId, month);
      state = AsyncValue.data(payroll);
      await _onGenerated(month);
      return payroll;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }
}

String _currentMonth() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
}
