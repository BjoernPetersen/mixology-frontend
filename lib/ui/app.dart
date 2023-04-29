import 'dart:async';
import 'dart:math';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:frontend/bloc/auth.dart';
import 'package:frontend/color_schemes.dart';
import 'package:frontend/ui/account.dart';
import 'package:frontend/ui/playlists.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class MixologyApp extends StatelessWidget {
  final Uri apiBaseUrl;
  final String? initialRefreshToken;
  final RouterConfig<Object> _router;

  MixologyApp({
    super.key,
    required this.apiBaseUrl,
    required this.initialRefreshToken,
  }) : _router = _createRouter();

  static void run(
    Uri apiBaseUrl, {
    String? refreshToken,
  }) {
    Bloc.transformer = sequential();
    usePathUrlStrategy();
    runApp(MixologyApp(
      apiBaseUrl: apiBaseUrl,
      initialRefreshToken: refreshToken,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(
        apiBaseUrl: apiBaseUrl,
        initialRefreshToken: initialRefreshToken,
      ),
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

extension on String {
  String? nullIfEmpty() {
    return isEmpty ? null : this;
  }
}

RouterConfig<Object> _createRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const PlaylistsPage(),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountPage(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) {
          return AuthCallbackPage(
          state: state.queryParameters['state'],
          error: state.queryParameters['error']?.nullIfEmpty(),
          code: state.queryParameters['code']?.nullIfEmpty(),
        );
        },
      ),
    ],
  );
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: AuthGuide(),
      ),
    );
  }
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
  }

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
            final error = state.error;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _AppLogo(),
                const SizedBox(height: 30),
                LoginButton(
                  action: () {
                    final bloc = BlocProvider.of<AuthBloc>(context);
                    bloc.add(const LoginEvent());
                  },
                ),
                if (error != null) Text(error),
              ],
            );
          case AuthStage.userAuthorization:
            // This will likely never be shown because of the listener.
            return LoginButton(
              action: () => _launchUrl(state.authorizationUrl),
            );
          case AuthStage.loggedIn:
            return const Text('You are logged in, but I am incompetent');
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
            context.go('/');
            break;
          default:
            break;
        }
      },
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(50)),
      child: Image.asset(
        'assets/logo.png',
        width: min(MediaQuery.of(context).size.width - 20, 200),
        filterQuality: FilterQuality.high,
      ),
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
