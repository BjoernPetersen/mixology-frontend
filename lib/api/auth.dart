import 'dart:async';
import 'dart:convert';

import 'package:frontend/api/util.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth.g.dart';

abstract class AuthApi {
  Future<LoginResponse> startLogin();

  Future<TokenPairResponse> loginCallback({
    required String state,
    required String? code,
    required String? error,
  });

  Future<RefreshResponse> refreshAccessToken({
    required String refreshToken,
  });

  FutureOr<void> close();

  factory AuthApi.http(Uri baseUrl) => _HttpAuthApi(baseUrl);
}

@immutable
@JsonSerializable(createToJson: false)
class LoginResponse {
  final String loginUrl;

  const LoginResponse(this.loginUrl);

  factory LoginResponse.fromJson(Json json) => _$LoginResponseFromJson(json);
}

@immutable
@JsonSerializable(createToJson: false)
class RefreshResponse {
  final String accessToken;
  final String? refreshToken;

  const RefreshResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory RefreshResponse.fromJson(Json json) =>
      _$RefreshResponseFromJson(json);
}

@immutable
@JsonSerializable(createToJson: false)
class TokenPairResponse {
  final String accessToken;
  final String refreshToken;

  const TokenPairResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory TokenPairResponse.fromJson(Json json) =>
      _$TokenPairResponseFromJson(json);
}

class _HttpAuthApi implements AuthApi {
  final Uri _baseUri;
  final http.Client _client;

  _HttpAuthApi(this._baseUri) : _client = RetryClient(http.Client());

  @override
  Future<LoginResponse> startLogin() async {
    final client = _client;
    final url = _baseUri.resolve('/auth/login');

    final http.Response response;
    try {
      response = await client.get(url);
    } on http.ClientException catch (e) {
      throw IoException(e);
    }

    switch (response.statusCode) {
      case 200:
        return response.deserialize(LoginResponse.fromJson);
      default:
        throw ResponseStatusException(response.statusCode);
    }
  }

  @override
  Future<TokenPairResponse> loginCallback({
    required String state,
    required String? code,
    required String? error,
  }) async {
    final client = _client;
    final url = _baseUri.resolve('/auth/callback').replace(
      queryParameters: {
        'state': state,
        'code': code,
        'error': error,
      },
    );

    final http.Response response;
    try {
      response = await client.get(url);
    } on http.ClientException catch (e) {
      throw IoException(e);
    }

    switch (response.statusCode) {
      case 200:
        return response.deserialize(TokenPairResponse.fromJson);
      default:
        throw ResponseStatusException(response.statusCode);
    }
  }

  @override
  Future<RefreshResponse> refreshAccessToken({
    required String refreshToken,
  }) async {
    final client = _client;
    final url = _baseUri.resolve('/auth/refresh');

    final http.Response response;
    try {
      response = await client.get(
        url,
        headers: {
          'Authorization': 'Bearer $refreshToken',
        },
      );
    } on http.ClientException catch (e) {
      throw IoException(e);
    }

    switch (response.statusCode) {
      case 200:
        return response.deserialize(RefreshResponse.fromJson);
      default:
        throw ResponseStatusException(response.statusCode);
    }
  }

  @override
  void close() {
    _client.close();
  }
}
