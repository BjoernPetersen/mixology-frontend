import 'dart:async';

import 'package:frontend/api/util.dart';
import 'package:frontend/auth_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:spotify_api/spotify_api.dart';

part 'mixology.g.dart';

abstract class MixologyApi {
  Future<AccountInfoResponse> getAccountInfo();

  Future<void> deleteAccount();

  Future<TokenInfo> getSpotifyAccessToken();

  Future<void> addMixPlaylist(String playlistId);

  Future<void> deleteMixPlaylist(String playlistId);

  Future<List<MixPlaylistResponse>> getMixPlaylists();

  Future<void> addCopyMixPlaylist(String? playlistId);

  Future<void> deleteCopyMixPlaylist(String targetId);

  Future<List<CopyMixPlaylistResponse>> getCopyMixPlaylists();

  FutureOr<void> close();

  factory MixologyApi.http({
    required AuthManager authManager,
  }) =>
      _HttpMixologyApi(authManager: authManager);
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

@immutable
@JsonSerializable(createToJson: false)
class AccessTokenResponse {
  final String token;
  final DateTime expiresAt;

  const AccessTokenResponse({
    required this.token,
    required this.expiresAt,
  });

  factory AccessTokenResponse.fromJson(Json json) =>
      _$AccessTokenResponseFromJson(json);
}

@immutable
@JsonSerializable(createToJson: false)
class MixPlaylistsResponse {
  final List<MixPlaylistResponse> playlists;

  const MixPlaylistsResponse(this.playlists);

  factory MixPlaylistsResponse.fromJson(Json json) =>
      _$MixPlaylistsResponseFromJson(json);
}

@immutable
@JsonSerializable(createToJson: false)
class MixPlaylistResponse {
  final String id;
  final String name;
  final DateTime? lastMix;

  const MixPlaylistResponse({
    required this.id,
    required this.name,
    required this.lastMix,
  });

  factory MixPlaylistResponse.fromJson(Json json) =>
      _$MixPlaylistResponseFromJson(json);
}

@immutable
@JsonSerializable(createToJson: false)
class CopyMixPlaylistsResponse {
  final List<CopyMixPlaylistResponse> playlists;

  const CopyMixPlaylistsResponse(this.playlists);

  factory CopyMixPlaylistsResponse.fromJson(Json json) =>
      _$CopyMixPlaylistsResponseFromJson(json);
}

@immutable
@JsonSerializable(createToJson: false)
class CopyMixPlaylistResponse {
  final String? sourceId;
  final String targetId;
  final DateTime? lastMix;

  const CopyMixPlaylistResponse({
    required this.sourceId,
    required this.targetId,
    required this.lastMix,
  });

  factory CopyMixPlaylistResponse.fromJson(Json json) =>
      _$CopyMixPlaylistResponseFromJson(json);
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
    required AuthManager authManager,
  })  : _client = RetryClient(
          _AuthClient(
            http.Client(),
            authManager: authManager,
          ),
        ),
        _baseUri = authManager.apiBaseUri;

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
  Future<TokenInfo> getSpotifyAccessToken() async {
    final client = _client;
    final url = _baseUri.resolve('/spotify/accessToken');

    final http.Response response;
    try {
      response = await client.get(url);
    } on http.ClientException catch (e) {
      throw IoException(e);
    }

    if (response.statusCode != 200) {
      throw ResponseStatusException(response.statusCode);
    }

    final result = response.deserialize(AccessTokenResponse.fromJson);
    return TokenInfo(
      value: result.token,
      expiration: result.expiresAt,
    );
  }

  @override
  Future<void> addMixPlaylist(String playlistId) async {
    final client = _client;
    final url = _baseUri.resolve('/mix/$playlistId');

    final http.Response response;
    try {
      response = await client.put(url);
    } on http.ClientException catch (e) {
      throw IoException(e);
    }

    if (response.statusCode != 204) {
      throw ResponseStatusException(response.statusCode);
    }
  }

  @override
  Future<void> deleteMixPlaylist(String playlistId) async {
    final client = _client;
    final url = _baseUri.resolve('/mix/$playlistId');

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
  Future<List<MixPlaylistResponse>> getMixPlaylists() async {
    final client = _client;
    final url = _baseUri.resolve('/mix');

    final http.Response response;
    try {
      response = await client.get(url);
    } on http.ClientException catch (e) {
      throw IoException(e);
    }

    if (response.statusCode != 200) {
      throw ResponseStatusException(response.statusCode);
    }

    final result = response.deserialize(MixPlaylistsResponse.fromJson);
    return result.playlists;
  }

  @override
  Future<void> addCopyMixPlaylist(String? playlistId) async {
    final client = _client;
    final url = _baseUri.resolve('/copyMix').replace(
      queryParameters: {if (playlistId != null) 'playlistId': playlistId},
    );

    final http.Response response;
    try {
      response = await client.put(url);
    } on http.ClientException catch (e) {
      throw IoException(e);
    }

    if (response.statusCode != 204) {
      throw ResponseStatusException(response.statusCode);
    }
  }

  @override
  Future<void> deleteCopyMixPlaylist(String targetId) async {
    final client = _client;
    final url = _baseUri.resolve('/copyMix/$targetId');

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
  Future<List<CopyMixPlaylistResponse>> getCopyMixPlaylists() async {
    final client = _client;
    final url = _baseUri.resolve('/copyMix');

    final http.Response response;
    try {
      response = await client.get(url);
    } on http.ClientException catch (e) {
      throw IoException(e);
    }

    if (response.statusCode != 200) {
      throw ResponseStatusException(response.statusCode);
    }

    final result = response.deserialize(CopyMixPlaylistsResponse.fromJson);
    return result.playlists;
  }

  @override
  void close() {
    _client.close();
  }
}
