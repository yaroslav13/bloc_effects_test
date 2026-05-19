import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_effects/bloc_effects.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart' as test;

/// A `blocTest`-style test helper for blocs that use `package:bloc_effects`.
///
/// Delegates all standard test infrastructure to `blocTest` and adds:
/// - [effects] — matcher for side-effects emitted via `emitEffect`.
/// - [skipEffects] — number of leading effects to ignore (mirrors [skip]).
///
/// ```dart
/// blocWithEffectsTest<CounterCubit, int, CounterEffect>(
///   'emits [1] and IncrementEffect when increment is called',
///   build: () => CounterCubit(),
///   act: (cubit) => cubit.increment(),
///   expect: () => [1],
///   effects: () => [const IncrementEffect()],
/// );
/// ```
@isTest
void blocWithEffectsTest<B extends BlocBase<State>, State, Effect>(
  String description, {
  required B Function() build,
  FutureOr<void> Function()? setUp,
  State Function()? seed,
  FutureOr<void> Function(B bloc)? act,
  Duration? wait,
  int skip = 0,
  int skipEffects = 0,
  dynamic Function()? expect,
  dynamic Function()? effects,
  dynamic Function(B bloc)? verify,
  dynamic Function()? errors,
  FutureOr<void> Function()? tearDown,
  dynamic tags,
}) {
  final emittedEffects = <Effect>[];
  StreamSubscription<Effect>? effectsSubscription;

  blocTest<B, State>(
    description,
    setUp: setUp,
    build: () {
      final bloc = build();
      if (bloc is! EffectsStreamable<Effect>) {
        throw ArgumentError(
          '${bloc.runtimeType} must extend BlocWithEffects or CubitWithEffects '
          'from package:bloc_effects with Effect type <$Effect>.',
        );
      }

      effectsSubscription = (bloc as EffectsStreamable<Effect>)
          .effectsStream
          .skip(skipEffects)
          .listen(emittedEffects.add);
      return bloc;
    },
    seed: seed,
    act: act,
    wait: wait,
    skip: skip,
    expect: expect,
    verify: (bloc) async {
      await effectsSubscription?.cancel();
      if (effects != null) {
        test.expect(emittedEffects, test.wrapMatcher(effects()));
      }
      await verify?.call(bloc);
    },
    errors: errors,
    tearDown: tearDown,
    tags: tags,
  );
}
