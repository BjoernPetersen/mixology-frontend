import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/loadable.dart';

export 'package:frontend/loadable.dart';

class LoadingAction<B extends Bloc<Object, S>, S, T> extends StatelessWidget {
  final Widget Function(BuildContext, T? value) builder;
  final Loadable<T> Function(S) getLoadable;
  final bool Function(T) isActive;
  final void Function(BuildContext, LoadingError)? onError;

  LoadingAction({
    super.key,
   required this.builder,
    @Deprecated('use builder')
     Widget? child,
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
        final value = (loadable is Loaded<T>) ? loadable.value : null;
        if (loadable is Loading<T> ||
            (loadable is Loaded<T> && !isActive(loadable.value))) {
          return AbsorbPointer(
            child: Opacity(
              opacity: 0.5,
              child: builder(context, value),
            ),
          );
        }

        // TODO: handle error

        return builder(context, value);
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
