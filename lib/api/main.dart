import 'dart:async';

import 'package:frontend/api/util.dart';
import 'package:frontend/auth_manager.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:json_annotation/json_annotation.dart';

part 'main.g.dart';

abstract class MixologyApi {
  Future<AccountInfoResponse> getAccountInfo();

  Future<void> deleteAccount();

  FutureOr<void> close();

  factory MixologyApi.http({
    required Uri baseUri,
    required AuthManager tokenManager,
  }) =>
      _HttpMixologyApi(
        baseUri: baseUri,
        authManager: tokenManager,
      );
}

@immutable
@JsonSerializable(createToJson: false)
class AccountInfoResponse {
  final String id;
  final String name;
  final String spotifyId;

  const AccountInfoResponse({
    required this.id,
    required this.name,
    required this.spotifyId,
  });

  factory AccountInfoResponse.fromJson(Json json) =>
      _$AccountInfoResponseFromJson(json);
}

class _AuthClient extends http.BaseClient {
  final AuthManager _authManager;
  final http.Client _inner;

  _AuthClient(
    this._inner, {
    required AuthManager authManager,
  }) : _authManager = authManager;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _authManager.accessToken;
    request.headers['Authorization'] = 'Bearer $token';
    return await _inner.send(request);
  }
}

class _HttpMixologyApi implements MixologyApi {
  final Uri _baseUri;
  final http.Client _client;

  _HttpMixologyApi({
    required Uri baseUri,
    required AuthManager authManager,
  })  : _client = RetryClient(
          _AuthClient(
            http.Client(),
            authManager: authManager,
          ),
        ),
        _baseUri = baseUri;

  @override
  Future<AccountInfoResponse> getAccountInfo() async {
    final client = _client;
    final url = _baseUri.resolve('/account');

    final http.Response response;
    try {
      response = await client.get(url);
    } on http.ClientException catch (e) {
      throw IoException(e);
    }

    switch (response.statusCode) {
      case 200:
        return response.deserialize(AccountInfoResponse.fromJson);
      default:
        throw ResponseStatusException(response.statusCode);
    }
  }

  @override
  Future<void> deleteAccount() async {
    final client = _client;
    final url = _baseUri.resolve('/account');

    final http.Response response;
    try {
      response = await client.delete(url);
    } on http.ClientException catch (e) {
      throw IoException(e);
    }

    if (response.statusCode != 204) {
      throw ResponseStatusException(response.statusCode);
    }
  }

  @override
  void close() {
    _client.close();
  }
}
