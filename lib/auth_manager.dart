import 'dart:async';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:frontend/api/auth.dart';
import 'package:meta/meta.dart';
import 'package:mutex/mutex.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _accessTokenKey = 'accessToken';
const _refreshTokenKey = 'refreshToken';

@immutable
class Token {
  final String value;
  final DateTime expiration;

  const Token({
    required this.value,
    required this.expiration,
  });

  bool get expiresSoon {
    return DateTime.now().add(const Duration(minutes: 1)).isAfter(expiration);
  }

  bool get isExpired {
    return DateTime.now().isAfter(expiration);
  }

  factory Token.fromValue(String value) {
    final jwt = JWT.decode(value);
    final expiration = DateTime.fromMillisecondsSinceEpoch(
      Duration(seconds: jwt.payload['exp']!).inMilliseconds,
    );
    return Token(
      value: value,
      expiration: expiration,
    );
  }
}

class LoginRequiredException implements Exception {}

class AuthManager {
  final AuthApi _authApi;
  final Mutex _mutex;
  late final SharedPreferences _preferences;
  Token? _accessToken;
  Token? _refreshToken;

  AuthManager(this._authApi) : _mutex = Mutex() {
    unawaited(_mutex.protect(() async {
      final preferences = await SharedPreferences.getInstance();
      _preferences = preferences;
      final accessToken = preferences.getString(_accessTokenKey);
      if (accessToken != null) {
        _accessToken = Token.fromValue(accessToken);
      }

      final refreshToken = preferences.getString(_refreshTokenKey);
      if (refreshToken != null) {
        _refreshToken = Token.fromValue(refreshToken);
      }
    }));
  }

  Future<bool> get hasRefreshToken async {
    return await _mutex.protect(() async {
      final refreshToken = _refreshToken;
      return refreshToken != null && !refreshToken.isExpired;
    });
  }

  Future<void> updateToken({
    required String refreshToken,
    required String accessToken,
  }) async {
    await _mutex.protect(() async {
      _unsafeSaveTokens(
        refreshToken: refreshToken,
        accessToken: accessToken,
      );
    });
  }

  Future<String> get accessToken async {
    return _mutex.protect(() async {
      Token? accessToken = _accessToken;
      if (accessToken == null || accessToken.expiresSoon) {
        return await _unsafeRefreshAccessToken();
      }
      return accessToken.value;
    });
  }

  Future<void> _unsafeSaveTokens({
    required String? refreshToken,
    required String accessToken,
  }) async {
    if (refreshToken != null) {
      final token = Token.fromValue(refreshToken);
      _refreshToken = token;
      await _preferences.setString(_refreshTokenKey, refreshToken);
    }

    final token = Token.fromValue(accessToken);
    _refreshToken = token;
    await _preferences.setString(_accessTokenKey, accessToken);
  }

  Future<String> _unsafeRefreshAccessToken() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null) {
      throw LoginRequiredException();
    } else if (refreshToken.isExpired) {
      throw LoginRequiredException();
    }

    final refreshResponse = await _authApi.refreshAccessToken(
      refreshToken: refreshToken.value,
    );
    final accessToken = refreshResponse.accessToken;
    final newRefreshToken = refreshResponse.refreshToken;
    await _unsafeSaveTokens(
      refreshToken: newRefreshToken,
      accessToken: accessToken,
    );
    return accessToken;
  }
}
