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

class DeleteAccount implements _MixologyEvent {
  const DeleteAccount();
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

@immutable
class MixologyState {
  final bool loggedOut;
  final Loadable<void> accountDeletion;
  final Loadable<AccountInfoResponse> accountInfo;

  const MixologyState._({
    required this.loggedOut,
    required this.accountDeletion,
    required this.accountInfo,
  });

  factory MixologyState.initial() {
    return const MixologyState._(
      loggedOut: false,
      accountDeletion: Unloaded(),
      accountInfo: Unloaded(),
    );
  }

  MixologyState copyWith({
    Loadable<void>? accountDeletion,
    Loadable<AccountInfoResponse>? accountInfo,
  }) {
    return MixologyState._(
      loggedOut: loggedOut,
      accountDeletion: accountDeletion ?? this.accountDeletion,
      accountInfo: accountInfo ?? this.accountInfo,
    );
  }

  factory MixologyState.loggedOut() => const MixologyState._(
        loggedOut: true,
        accountDeletion: Unloaded(),
        accountInfo: Unloaded(),
      );
}

class MixologyBloc extends Bloc<_MixologyEvent, MixologyState> {
  final AuthManager _authManager;
  final MixologyApi _api;

  MixologyBloc(this._authManager)
      : _api = MixologyApi.http(authManager: _authManager),
        super(MixologyState.initial()) {
    on<GetAccount>(_getAccount);
    on<DeleteAccount>(_deleteAccount);
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
    emit(state.copyWith(accountInfo: Loaded(accountInfo)));
  }

  Future<void> _deleteAccount(
    DeleteAccount event,
    Emitter<MixologyState> emit,
  ) async {
    await _api.deleteAccount();
    await _authManager.logout();

    emit(MixologyState.loggedOut());
  }

  @override
  Future<void> close() async {
    await _api.close();
    await super.close();
  }
}
