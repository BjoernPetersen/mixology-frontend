import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:frontend/api/main.dart';
import 'package:frontend/auth_manager.dart';
import 'package:frontend/loadable.dart';
import 'package:meta/meta.dart';
import 'package:spotify_api/extension.dart';
import 'package:spotify_api/spotify_api.dart';

@sealed
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

class ListPlaylists implements _MixologyEvent {
  final int? pageSize;
  final Page<Playlist<PageRef<PlaylistTrack>>>? nextFrom;
  final Page<Playlist<PageRef<PlaylistTrack>>>? previousFrom;

  const ListPlaylists({
    this.pageSize,
  })  : nextFrom = null,
        previousFrom = null;

  const ListPlaylists.next({
    this.pageSize,
    required Page<Playlist<PageRef<PlaylistTrack>>>? from,
  })  : nextFrom = from,
        previousFrom = null;

  const ListPlaylists.previous({
    required Page<Playlist<PageRef<PlaylistTrack>>>? from,
  })  : pageSize = null,
        nextFrom = null,
        previousFrom = from;
}

@immutable
class MixologyState {
  final bool loggedOut;
  final Loadable<void> accountDeletion;
  final Loadable<AccountInfoResponse> accountInfo;
  final Loadable<Page<Playlist<PageRef<PlaylistTrack>>>> playlists;

  const MixologyState._({
    required this.loggedOut,
    required this.accountDeletion,
    required this.accountInfo,
    required this.playlists,
  });

  const MixologyState._unloaded({
    required this.loggedOut,
  })  : accountDeletion = const Unloaded(),
        accountInfo = const Unloaded(),
        playlists = const Unloaded();

  factory MixologyState.initial() {
    return const MixologyState._unloaded(loggedOut: false);
  }

  MixologyState copyWith({
    Loadable<void>? accountDeletion,
    Loadable<AccountInfoResponse>? accountInfo,
    Loadable<Page<Playlist<PageRef<PlaylistTrack>>>>? playlists,
  }) {
    return MixologyState._(
      loggedOut: loggedOut,
      accountDeletion: accountDeletion ?? this.accountDeletion,
      accountInfo: accountInfo ?? this.accountInfo,
      playlists: playlists ?? this.playlists,
    );
  }

  factory MixologyState.loggedOut() =>
      const MixologyState._unloaded(loggedOut: true);
}

class MixologyBloc extends Bloc<_MixologyEvent, MixologyState> {
  final AuthManager _authManager;
  final MixologyApi _api;
  late final SpotifyWebApi _spotifyApi;

  MixologyBloc(this._authManager)
      : _api = MixologyApi.http(authManager: _authManager),
        super(MixologyState.initial()) {
    _spotifyApi = SpotifyWebApi(
      refresher: _MixologyAccessTokenRefresher(_api),
    );

    on<GetAccount>(_getAccount);
    on<DeleteAccount>(_deleteAccount);
    on<ListPlaylists>(_listPlaylists);
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

    try {
      await _api.deleteAccount();
    } catch (e) {
      emit(state.copyWith(
        accountDeletion: LoadingError('Could not delete account'),
      ));
      return;
    }

    await _authManager.logout();

    emit(MixologyState.loggedOut());
  }

  Future<void> _listPlaylists(
    ListPlaylists event,
    Emitter<MixologyState> emit,
  ) async {
    emit(state.copyWith(playlists: Loading()));

    final nextFrom = event.nextFrom;
    final previousFrom = event.previousFrom;

    final Future<Page<Playlist<PageRef<PlaylistTrack>>>> load;
    if (nextFrom == null && previousFrom == null) {
      // Load initial set
      load = _spotifyApi.playlists.getCurrentUsersPlaylists();
    } else {
      final paginator = await _spotifyApi.paginator(nextFrom ?? previousFrom!);
      if (previousFrom != null) {
        if (previousFrom.previous == null) {
          emit(state.copyWith(
            playlists: LoadingError(
              'No previous page available',
              state.playlists,
            ),
          ));
          return;
        }
        load = paginator.previousPage().then((p) => p!.page);
      } else {
        if (nextFrom!.next == null) {
          emit(state.copyWith(
            playlists: LoadingError(
              'No next page available',
              state.playlists,
            ),
          ));
          return;
        }
        load = paginator.nextPage().then((p) => p!.page);
      }

      try {
        final result = await load;
        emit(state.copyWith(playlists: Loaded(result)));
      } catch (e) {
        emit(state.copyWith(
          playlists: LoadingError(
            'Could not load playlists',
            state.playlists,
          ),
        ));
      }
    }
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
