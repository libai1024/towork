import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reactive repository contract with immutable collection snapshots.
///
/// Domain entities own the immutability of their nested values. Keeping the
/// notifier contract makes implementations replaceable through Riverpod without
/// tying callers to the in-memory implementation.
abstract class ListStore<T> extends StateNotifier<List<T>> {
  ListStore(Iterable<T> initial) : super(List<T>.unmodifiable(initial));

  List<T> get snapshot => state;

  @override
  @protected
  set state(List<T> value) => super.state = List<T>.unmodifiable(value);
}
