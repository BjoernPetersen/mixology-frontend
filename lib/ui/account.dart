import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/api/main.dart';
import 'package:frontend/bloc/auth.dart';
import 'package:frontend/bloc/mixology.dart';
import 'package:frontend/ui/authenticated.dart';
import 'package:frontend/ui/constants.dart';
import 'package:frontend/ui/loading.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        actions: const [
          _LogoutButton(),
        ],
      ),
      body: Authenticated(
        builder: (context) => const _AccountPageBody(),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Log out',
      icon: const Icon(Icons.logout, size: kAppBarActionSize),
      onPressed: () {
        final bloc = BlocProvider.of<AuthBloc>(context);
        bloc.add(const LogoutEvent());
      },
    );
  }
}

class _AccountPageBody extends StatefulWidget {
  const _AccountPageBody();

  @override
  State<_AccountPageBody> createState() => _AccountPageBodyState();
}

class _AccountPageBodyState extends State<_AccountPageBody> {
  @override
  void initState() {
    super.initState();
    BlocProvider.of<MixologyBloc>(context).add(GetAccount());
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: AccountInfoCard(),
    );
  }
}

class AccountInfoCard extends StatelessWidget {
  const AccountInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 200,
        width: 400,
        padding: const EdgeInsets.only(
          top: 20,
          left: 10,
          right: 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Expanded(child: _AccountInfo()),
            const Divider(height: 0),
            ButtonBar(
              mainAxisSize: MainAxisSize.max,
              children: [
                LoadingAction<MixologyBloc, MixologyState, void>(
                  getLoadable: (state) => state.accountDeletion,
                  child: const _DeleteAccountButton(),
                ),
                LoadingAction<MixologyBloc, MixologyState, AccountInfoResponse>(
                  getLoadable: (state) => state.accountInfo,
                  onError: showErrorSnackBar,
                  child: const _RefreshAccountButton(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountInfo extends StatelessWidget {
  const _AccountInfo();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MixologyBloc, MixologyState>(
      builder: (context, state) {
        final loadable = state.accountInfo;

        if (loadable is Loaded<AccountInfoResponse>) {
          final accountInfo = loadable.value;
          return Column(
            children: [
              Text(
                'Logged in as ${accountInfo.name}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Text(
                'User ID: ${accountInfo.id}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          );
        }

        if (loadable is LoadingError<AccountInfoResponse>) {
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

        return const Center(child: LinearProgressIndicator());
      },
    );
  }
}

class _RefreshAccountButton extends StatelessWidget {
  const _RefreshAccountButton();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        final bloc = BlocProvider.of<MixologyBloc>(context);
        bloc.add(GetAccount(Duration.zero));
      },
      child: const Text('Refresh'),
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        final bloc = BlocProvider.of<MixologyBloc>(context);
        final result = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Account'),
              content: const Text('This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );

        if (result == true) {
          bloc.add(const DeleteAccount());
        }
      },
      child: const Text('Delete Account'),
    );
  }
}