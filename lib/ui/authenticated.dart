import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/bloc/auth.dart';
import 'package:frontend/bloc/mixology.dart';
import 'package:go_router/go_router.dart';

class Authenticated extends StatelessWidget {
  final Widget Function(BuildContext) builder;

  const Authenticated({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.stage == AuthStage.loggedIn) {
          return BlocProvider(
            create: (_) => MixologyBloc(state.authManager),
            child: builder(context),
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
      listener: (context, state) {
        switch (state.stage) {
          case AuthStage.loggedIn:
          case AuthStage.loading:
            return;
          default:
            context.go('/auth/login');
        }
      },
    );
  }
}
