import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/bloc/auth.dart';
import 'package:frontend/bloc/mixology.dart';
import 'package:frontend/ui/authenticated.dart';
import 'package:frontend/ui/constants.dart';
import 'package:frontend/ui/loading.dart';
import 'package:go_router/go_router.dart';
import 'package:spotify_api/spotify_api.dart';

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Authenticated(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Your Playlists'),
          actions: const [
            _AccountButton(),
          ],
        ),
        body: const Center(child: _PlaylistsPageBody()),
      ),
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.push('/account'),
      icon: const Icon(Icons.account_circle, size: kAppBarActionSize),
      tooltip: 'My Account',
    );
  }
}

class _PlaylistsPageBody extends StatelessWidget {
  const _PlaylistsPageBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      constraints: BoxConstraints(
        maxWidth: min(MediaQuery.of(context).size.width, 800),
      ),
      child: const _PlaylistsPager(),
    );
  }
}

class _PlaylistsPager extends StatefulWidget {
  const _PlaylistsPager();

  @override
  State<_PlaylistsPager> createState() => _PlaylistsPagerState();
}

class _PlaylistsPagerState extends State<_PlaylistsPager> {
  @override
  void initState() {
    super.initState();
    BlocProvider.of<MixologyBloc>(context).add(const ListPlaylists());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MixologyBloc, MixologyState>(
      listener: (context, state) {
        final playlists = state.playlists;
        if (playlists is LoadingError<PlaylistPage>) {
          showErrorSnackBar(context, playlists);
        }
      },
      buildWhen: (pre, post) {
        return (pre.playlists is Loading<PlaylistPage>) !=
            (post.playlists is Loading<PlaylistPage>);
      },
      builder: (context, state) => Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Expanded(child: _CurrentPlaylistPage()),
          if (state.playlists is Loading<PlaylistPage> &&
              state.playlists is Loaded<PlaylistPage>)
            const LinearProgressIndicator(),
          const ButtonBar(
            children: [
              _PreviousPageButton(),
              _NextPageButton(),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviousPageButton extends StatelessWidget {
  const _PreviousPageButton();

  @override
  Widget build(BuildContext context) {
    return LoadingAction<MixologyBloc, MixologyState, PlaylistPage>(
      child: TextButton(
        onPressed: () {
          final bloc = BlocProvider.of<MixologyBloc>(context);
          final playlists = bloc.state.playlists as Loaded<PlaylistPage>;
          bloc.add(ListPlaylists.previous(
            from: playlists.value,
          ));
        },
        child: const Text('Previous'),
      ),
      getLoadable: (state) => state.playlists,
      isActive: (page) => page.previous != null,
    );
  }
}

class _NextPageButton extends StatelessWidget {
  const _NextPageButton();

  @override
  Widget build(BuildContext context) {
    return LoadingAction<MixologyBloc, MixologyState, PlaylistPage>(
      child: TextButton(
        onPressed: () {
          final bloc = BlocProvider.of<MixologyBloc>(context);
          final playlists = bloc.state.playlists as Loaded<PlaylistPage>;
          bloc.add(ListPlaylists.next(
            from: playlists.value,
          ));
        },
        child: const Text('Next'),
      ),
      getLoadable: (state) => state.playlists,
      isActive: (page) => page.next != null,
    );
  }
}

class _CurrentPlaylistPage extends StatelessWidget {
  const _CurrentPlaylistPage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MixologyBloc, MixologyState>(
      buildWhen: (pre, post) => pre.playlists != post.playlists,
      builder: (context, state) {
        final playlists = state.playlists;
        if (playlists is Loaded<PlaylistPage>) {
          final page = playlists.value;
          return _PlaylistsList(page.items);
        }

        if (playlists is LoadingError<PlaylistPage>) {
          return Opacity(
            opacity: 0.8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 50),
                const SizedBox(height: 10),
                const Text('This content could not be loaded.'),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    final bloc = BlocProvider.of<MixologyBloc>(context);
                    bloc.add(const ListPlaylists());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _PlaylistsList extends StatelessWidget {
  final List<Playlist<PageRef<PlaylistTrack>>> playlists;

  const _PlaylistsList(this.playlists);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) => _PlaylistCard(playlists[index]),
      itemCount: playlists.length,
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Playlist<PageRef<PlaylistTrack>> playlist;

  const _PlaylistCard(this.playlist);

  @override
  Widget build(BuildContext context) {
    final description = playlist.description;
    return Card(
      child: ListTile(
        title: Text(
          playlist.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: description == null
            ? null
            : Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
        leading: _PlaylistKindIndicator(playlist),
      ),
    );
  }
}

class _PlaylistKindIndicator extends StatelessWidget {
  final Playlist<PageRef<PlaylistTrack>> playlist;

  const _PlaylistKindIndicator(this.playlist);

  @override
  Widget build(BuildContext context) {
    const double iconSize = 30;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final ownId = state.spotifyUserId;
        if (playlist.isCollaborative) {
          return const Tooltip(
            message: 'A collaborative playlist',
            child: Icon(
              Icons.group,
              size: iconSize,
            ),
          );
        } else if (playlist.owner.id == ownId) {
          if (playlist.isPublic == true) {
            return const Tooltip(
              message: 'Your public playlist',
              child: Icon(
                Icons.public,
                size: iconSize,
              ),
            );
          } else {
            return const Tooltip(
              message: 'Your private playlist',
              child: Icon(
                Icons.person,
                size: iconSize,
              ),
            );
          }
        } else {
          return const Tooltip(
            message: "Someone else's playlist",
            child: Icon(
              Icons.not_interested,
              size: iconSize,
            ),
          );
        }
      },
    );
  }
}
