import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/api/main.dart';
import 'package:frontend/bloc/mixology.dart';
import 'package:frontend/ui/authenticated.dart';

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
    return Center(
      child: BlocBuilder<MixologyBloc, MixologyState>(
        builder: (context, state) {
          final accountInfo = state.accountInfo;
          if (accountInfo is Loaded<AccountInfoResponse>) {
            return AccountInfoCard(
              child: AccountInfo(accountInfo.value),
            );
          }

          return const AccountInfoCard(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
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
        child: child,
      ),
    );
  }
}

class AccountInfo extends StatelessWidget {
  final AccountInfoResponse accountInfo;

  const AccountInfo(
    this.accountInfo, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
        const Spacer(),
        const Divider(height: 0),
        ButtonBar(
          mainAxisSize: MainAxisSize.max,
          children: [
            TextButton(
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
            ),
            TextButton(
              onPressed: () {
                final bloc = BlocProvider.of<MixologyBloc>(context);
                bloc.add(GetAccount(Duration.zero));
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
      ],
    );
  }
}
