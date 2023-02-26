import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/loadable.dart';

export 'package:frontend/loadable.dart';

class LoadingAction<B extends Bloc<Object, S>, S, T> extends StatelessWidget {
  final Widget child;
  final Loadable<T> Function(S) getLoadable;
  final bool Function(T) isActive;
  final void Function(BuildContext, LoadingError)? onError;

  LoadingAction({
    super.key,
    required this.child,
    required this.getLoadable,
    bool Function(T)? isActive,
    this.onError,
  }) : isActive = (isActive ?? (_) => true);

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
        if (loadable is Loading<T> ||
            (loadable is Loaded<T> && !isActive(loadable.value))) {
          return AbsorbPointer(
            child: Opacity(
              opacity: 0.5,
              child: child,
            ),
          );
        }

        // TODO: handle error

        return child;
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
