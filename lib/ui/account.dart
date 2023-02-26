import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/api/main.dart';
import 'package:frontend/bloc/mixology.dart';
import 'package:frontend/ui/authenticated.dart';
import 'package:frontend/ui/loading.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Authenticated(
        builder: (context) => const AccountPageBody(),
      ),
    );
  }
}

class AccountPageBody extends StatefulWidget {
  const AccountPageBody({super.key});

  @override
  State<AccountPageBody> createState() => _AccountPageBodyState();
}

class _AccountPageBodyState extends State<AccountPageBody> {
  @override
  void initState() {
    super.initState();
    BlocProvider.of<MixologyBloc>(context).add(GetAccount());
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: AccountInfoCard(
        child: AccountInfo(),
      ),
    );
  }
}

class AccountInfoCard extends StatelessWidget {
  final Widget child;

  const AccountInfoCard({super.key, required this.child});

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
            const Expanded(child: AccountInfo()),
            const Divider(height: 0),
            ButtonBar(
              mainAxisSize: MainAxisSize.max,
              children: [
                LoadingAction<MixologyBloc, MixologyState, void>(
                  getLoadable: (state) => state.accountDeletion,
                  child: const DeleteAccountButton(),
                ),
                LoadingAction<MixologyBloc, MixologyState, AccountInfoResponse>(
                  getLoadable: (state) => state.accountInfo,
                  onError: showErrorSnackBar,
                  child: const RefreshAccountButton(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AccountInfo extends StatelessWidget {
  const AccountInfo({
    super.key,
  });

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

void showErrorSnackBar(BuildContext context, LoadingError errorMessage) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(errorMessage.error),
    ),
  );
}

class RefreshAccountButton extends StatelessWidget {
  const RefreshAccountButton({super.key});

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

class DeleteAccountButton extends StatelessWidget {
  const DeleteAccountButton({super.key});

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
