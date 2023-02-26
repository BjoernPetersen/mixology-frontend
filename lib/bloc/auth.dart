import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:frontend/api/auth.dart';
import 'package:frontend/auth_manager.dart';
import 'package:meta/meta.dart';

@immutable
abstract class _AuthEvent {
  const _AuthEvent();
}

@immutable
class _InitEvent implements _AuthEvent {
  const _InitEvent();
}

@immutable
class LoginEvent implements _AuthEvent {
  const LoginEvent();
}

@immutable
class UserAuthorizedEvent implements _AuthEvent {
  final String? code;
  final String? error;
  final String state;

  const UserAuthorizedEvent({
    required this.state,
    required this.code,
    required this.error,
  });
}

enum AuthStage {
  loading,
  loginRequired,
  userAuthorization,
  loggedIn,
}

@immutable
class AuthState {
  final AuthStage stage;
  final Uri? _authorizationUrl;
  final AuthManager? _authManager;
  final String? error;

  Uri get authorizationUrl {
    if (stage == AuthStage.userAuthorization) {
      return _authorizationUrl!;
    } else {
      throw StateError(
        'Authorization URL is only available in userAuthorization stage',
      );
    }
  }

  AuthManager get authManager {
    if (stage == AuthStage.loggedIn) {
      return _authManager!;
    } else {
      throw StateError(
        'Authorization URL is only available in userAuthorization stage',
      );
    }
  }

  const AuthState._({
    required this.stage,
    Uri? authorizationUrl,
    AuthManager? authManager,
    this.error,
  })  : _authorizationUrl = authorizationUrl,
        _authManager = authManager;

  factory AuthState.loading() {
    return const AuthState._(
      stage: AuthStage.loading,
    );
  }

  factory AuthState.loginRequired([String? error]) {
    return AuthState._(
      stage: AuthStage.loginRequired,
      error: error,
    );
  }

  factory AuthState.userAuthorization(Uri authorizationUrl) {
    return AuthState._(
      stage: AuthStage.userAuthorization,
      authorizationUrl: authorizationUrl,
    );
  }

  factory AuthState.loggedIn(AuthManager authManager) {
    return AuthState._(
      stage: AuthStage.loggedIn,
      authManager: authManager,
    );
  }
}

class AuthBloc extends Bloc<_AuthEvent, AuthState> {
  final AuthApi _api;
  late final AuthManager _authManager;

  AuthBloc({required Uri apiBaseUrl})
      : _api = AuthApi.http(apiBaseUrl),
        super(AuthState.loading()) {
    _authManager = AuthManager(_api);

    on<_AuthEvent>(_onEvent);

    add(const _InitEvent());
  }

  Future<void> _onEvent(_AuthEvent event, Emitter<AuthState> emit) {
    if (event is _InitEvent) {
      return _init(event, emit);
    } else if (event is LoginEvent) {
      return _login(event, emit);
    } else if (event is UserAuthorizedEvent) {
      return _userAuthorized(event, emit);
    } else {
      throw ArgumentError.value(event, 'event', 'unknown even type');
    }
  }

  Future<void> _init(_InitEvent event, Emitter<AuthState> emit) async {
    if (await _authManager.hasRefreshToken) {
      emit(AuthState.loggedIn(_authManager));
    } else {
      emit(AuthState.loginRequired());
    }
  }

  Future<void> _login(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthState.loading());

    final LoginResponse response;
    try {
      response = await _api.startLogin();
    } catch (e) {
      emit(AuthState.loginRequired(e.toString()));
      return;
    }

    emit(AuthState.userAuthorization(Uri.parse(response.loginUrl)));
  }

  Future<void> _userAuthorized(
    UserAuthorizedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    final TokenPairResponse response;
    try {
      response = await _api.loginCallback(
        state: event.state,
        code: event.code,
        error: event.error,
      );
    } catch (e) {
      emit(AuthState.loginRequired(e.toString()));
      return;
    }

    await _authManager.updateToken(
      refreshToken: response.refreshToken,
      accessToken: response.accessToken,
    );

    emit(AuthState.loggedIn(_authManager));
  }
}
