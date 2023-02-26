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
    return BlocBuilder<MixologyBloc, MixologyState>(
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
        constraints: const BoxConstraints(minHeight: 600, minWidth: 400),
        child: child,
      ),
    );
  }
}

class AccountInfo extends StatelessWidget {
  final AccountInfoResponse accountInfo;

  const AccountInfo(this.accountInfo, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(accountInfo.name);
  }
}
