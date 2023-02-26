import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/loadable.dart';

export 'package:frontend/loadable.dart';

class LoadingAction<B extends Bloc<Object, S>, S, T> extends StatelessWidget {
  final Widget child;
  final Loadable<T> Function(S) getLoadable;
  final void Function(BuildContext, LoadingError)? onError;

  const LoadingAction({
    super.key,
    required this.child,
    required this.getLoadable,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<B, S>(
      listener: (context, state) {
        final loadable = getLoadable(state);
        if (loadable is LoadingError<T>) {
          final onError = this.onError;
          if (onError != null) {
            onError(context, loadable);
          }
        }
      },
      builder: (context, state) {
        final loadable = getLoadable(state);
        if (loadable is Loading<T>) {
          return AbsorbPointer(
            child: Opacity(
              opacity: 0.5,
              child: child,
            ),
          );
        }
        return child;
      },
    );
  }
}
