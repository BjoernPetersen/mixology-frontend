import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:frontend/api/main.dart';
import 'package:frontend/auth_manager.dart';
import 'package:meta/meta.dart';

@immutable
abstract class _MixologyEvent {
  const _MixologyEvent();
}

class GetAccount implements _MixologyEvent {
  final DateTime maxAge;

  GetAccount([
    Duration maxAge = const Duration(seconds: 10),
  ]) : maxAge = DateTime.now().subtract(maxAge);
}

@sealed
abstract class Loadable<T> {
  const Loadable._();
}

class Loaded<T> implements Loadable<T> {
  final DateTime loadedAt;
  final T value;

  Loaded(this.value) : loadedAt = DateTime.now();
}

class Unloaded<T> implements Loadable<T> {
  const Unloaded();
}

extension _Loading<T> on T {
  Loaded<T> get loaded => Loaded(this);
}

@immutable
class MixologyState {
  final Loadable<AccountInfoResponse> accountInfo;

  const MixologyState._({
    required this.accountInfo,
  });

  factory MixologyState.initial() {
    return const MixologyState._(
      accountInfo: Unloaded(),
    );
  }

  MixologyState copyWith({AccountInfoResponse? accountInfo}) {
    return MixologyState._(
      accountInfo: accountInfo?.loaded ?? this.accountInfo,
    );
  }
}

class MixologyBloc extends Bloc<_MixologyEvent, MixologyState> {
  final MixologyApi _api;

  MixologyBloc(AuthManager authManager)
      : _api = MixologyApi.http(
          baseUri: authManager.apiBaseUri,
          authManager: authManager,
        ),
        super(MixologyState.initial()) {
    on<GetAccount>(_getAccount);
  }

  bool _isFresh<T>(Loadable<T> value, DateTime maxAge) {
    if (value is! Loaded<T>) {
      return false;
    }

    return value.loadedAt.isAfter(maxAge);
  }

  Future<void> _getAccount(
    GetAccount event,
    Emitter<MixologyState> emit,
  ) async {
    if (_isFresh(state.accountInfo, event.maxAge)) {
      return;
    }

    final accountInfo = await _api.getAccountInfo();
    emit(state.copyWith(accountInfo: accountInfo));
  }
}
