import 'package:meta/meta.dart';

@sealed
abstract class Loadable<T> {
  const Loadable._();
}

@immutable
class Loaded<T> implements Loadable<T> {
  final DateTime loadedAt;
  final T value;

  Loaded(this.value) : loadedAt = DateTime.now();
}

@sealed
@immutable
abstract class LoadingError<T> implements Loadable<T> {
  final String error;

  const LoadingError._(this.error);

  factory LoadingError(
    String error, [
    Loadable<T>? previous,
  ]) {
    if (previous is Loaded<T>) {
      return _RefreshError(error, previous);
    } else {
      return _InitialError(error);
    }
  }
}

@immutable
class _InitialError<T> extends LoadingError<T> {
  const _InitialError(String error) : super._(error);
}

@immutable
class _RefreshError<T> extends LoadingError<T> implements Loaded<T> {
  final Loaded<T> _previous;

  const _RefreshError(String error, this._previous) : super._(error);

  @override
  DateTime get loadedAt => _previous.loadedAt;

  @override
  T get value => _previous.value;
}

@sealed
@immutable
abstract class Loading<T> implements Loadable<T> {
  factory Loading([
    Loadable<T>? previous,
  ]) {
    if (previous is Loaded<T>) {
      return _Reloading(previous);
    } else {
      return const _InitialLoading();
    }
  }
}

@immutable
class _InitialLoading<T> implements Loading<T> {
  const _InitialLoading();
}

@immutable
class _Reloading<T> implements Loaded<T>, Loading<T> {
  final Loaded<T> _previous;

  const _Reloading(this._previous);

  @override
  DateTime get loadedAt => _previous.loadedAt;

  @override
  T get value => _previous.value;
}

@immutable
class Unloaded<T> implements Loadable<T> {
  const Unloaded();
}
