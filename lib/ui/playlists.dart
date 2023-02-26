import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/bloc/mixology.dart';
import 'package:frontend/ui/authenticated.dart';
import 'package:frontend/ui/loading.dart';
import 'package:spotify_api/spotify_api.dart';

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Playlists'),
      ),
      body: Authenticated(
        builder: (context) => const Center(child: _PlaylistsPageBody()),
      ),
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
    return BlocListener<MixologyBloc, MixologyState>(
      listener: (context, state) {
        final playlists = state.playlists;
        if (playlists is LoadingError<PlaylistPage>) {
          showErrorSnackBar(context, playlists);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: const [
          Expanded(child: _CurrentPlaylistPage()),
          ButtonBar(
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
              children: const [
                Icon(Icons.error),
                SizedBox(height: 10),
                Text('This content could not be loaded.'),
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
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        final description = playlist.description;
        return Card(
          child: ListTile(
            title: Text(playlist.name),
            subtitle: description == null ? null : Text(description),
          ),
        );
      },
      itemCount: playlists.length,
    );
  }
}
