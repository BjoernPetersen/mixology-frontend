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
            child: LogoutListener(
              child: builder(context),
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
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

class LogoutListener extends StatelessWidget {
  final Widget child;

  const LogoutListener({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<MixologyBloc, MixologyState>(
      listener: (context, state) {
        if (state.loggedOut) {
          BlocProvider.of<AuthBloc>(context).add(const LogoutEvent());
          context.go('/auth/login');
        }
      },
      child: child,
    );
  }
}
