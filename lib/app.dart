import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/bloc/auth.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/color_schemes.dart';
import 'package:url_launcher/url_launcher.dart';

class MixologyApp extends StatelessWidget {
  final Uri apiBaseUrl;
  final RouterConfig<Object> _router;

  MixologyApp({super.key, required this.apiBaseUrl})
      : _router = _createRouter();

  static void run(Uri apiBaseUrl) {
    Bloc.transformer = sequential();
    usePathUrlStrategy();
    runApp(MixologyApp(
      apiBaseUrl: apiBaseUrl,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(apiBaseUrl: apiBaseUrl),
      lazy: false,
      child: MaterialApp.router(
        title: 'Mixology',
        theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
        darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
        routerConfig: _router,
      ),
    );
  }
}

RouterConfig<Object> _createRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => AuthCallbackPage(
          state: state.queryParams['state'],
          error: state.queryParams['error'],
          code: state.queryParams['code'],
        ),
      ),
      GoRoute(
        path: '/success',
        builder: (context, state) => const SuccessPage(),
      ),
    ],
  );
}

class AuthCallbackPage extends StatefulWidget {
  final String? state;
  final String? error;
  final String? code;

  const AuthCallbackPage({
    super.key,
    required this.state,
    required this.error,
    required this.code,
  });

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  @override
  void initState() {
    super.initState();
    final state = widget.state;
    if (state != null) {
      BlocProvider.of<AuthBloc>(context).add(UserAuthorizedEvent(
        state: state,
        code: widget.code,
        error: widget.error,
      ));
    }
    // TODO: show error if state is null

    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('yay'),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: AuthGuide(),
      ),
    );
  }
}

class AuthGuide extends StatelessWidget {
  const AuthGuide({super.key});

  void _launchUrl(Uri url) {
    unawaited(launchUrl(
      url,
      webOnlyWindowName: '_self',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      builder: (context, state) {
        switch (state.stage) {
          case AuthStage.loginRequired:
            // TODO: show error
            return LoginButton(
              action: () =>
                  BlocProvider.of<AuthBloc>(context).add(const LoginEvent()),
            );
          case AuthStage.userAuthorization:
            // This will likely never be shown because of the listener.
            return LoginButton(
              action: () => _launchUrl(state.authorizationUrl),
            );
          case AuthStage.loading:
          default:
            return const CircularProgressIndicator();
        }
      },
      listenWhen: (pre, post) => pre.stage != post.stage,
      listener: (context, state) {
        switch (state.stage) {
          case AuthStage.userAuthorization:
            _launchUrl(state.authorizationUrl);
            break;
          case AuthStage.loggedIn:
            context.go('/success');
            break;
          default:
            break;
        }
      },
    );
  }
}

class LoginButton extends StatelessWidget {
  final void Function() action;

  const LoginButton({
    super.key,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: action,
      child: const Text('Log in with Spotify'),
    );
  }
}
