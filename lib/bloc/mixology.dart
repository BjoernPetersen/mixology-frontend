import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:frontend/api/main.dart';
import 'package:frontend/auth_manager.dart';
import 'package:frontend/loadable.dart';
import 'package:meta/meta.dart';
import 'package:spotify_api/spotify_api.dart';
import 'package:spotify_api/extension.dart';

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
  late final SpotifyWebApi _spotifyApi;

  MixologyBloc(this._authManager)
      : _api = MixologyApi.http(authManager: _authManager),
        super(MixologyState.initial()) {
    _spotifyApi = SpotifyWebApi(refresher: _MixologyAccessTokenRefresher(_api));

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

    emit(state.copyWith(accountInfo: Loading(state.accountInfo)));

    try {
      final accountInfo = await _api.getAccountInfo();
      emit(state.copyWith(accountInfo: Loaded(accountInfo)));
    } catch (e) {
      emit(state.copyWith(
        accountInfo: LoadingError(
          'An error occurred during account refresh',
          state.accountInfo,
        ),
      ));
    }
  }

  Future<void> _deleteAccount(
    DeleteAccount event,
    Emitter<MixologyState> emit,
  ) async {
    emit(state.copyWith(accountDeletion: Loading()));

    await _api.deleteAccount();
    await _authManager.logout();

    emit(MixologyState.loggedOut());
  }

  @override
  Future<void> close() async {
    _spotifyApi.close();
    await _api.close();
    await super.close();
  }
}

class _MixologyAccessTokenRefresher implements AccessTokenRefresher {
  final MixologyApi _api;

  _MixologyAccessTokenRefresher(this._api);

  @override
  String get clientId {
    // Not actually used in this implementation
    throw UnimplementedError();
  }

  @override
  Future<TokenInfo> retrieveToken(RequestsClient client) async {
    return await _api.getSpotifyAccessToken();
  }
}
