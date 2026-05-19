import 'package:bloc/bloc.dart' show Emitter;
import 'package:bloc_effects/bloc_effects.dart';
import 'package:bloc_effects_test/bloc_effects_test.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

void main() {
  mainCubit();
  mainBloc();
}

void mainCubit() {
  group('CounterCubit', () {
    blocWithEffectsTest<CounterCubit, int, CounterEffect>(
      'emits [] and no effects when nothing is called',
      build: CounterCubit.new,
      expect: () => const <int>[],
      effects: () => const <CounterEffect>[],
    );

    blocWithEffectsTest<CounterCubit, int, CounterEffect>(
      'emits [1] and [IncrementEffect] when increment is called',
      build: CounterCubit.new,
      act: (cubit) => cubit.increment(),
      expect: () => const <int>[1],
      effects: () => const <CounterEffect>[IncrementEffect()],
    );

    blocWithEffectsTest<CounterCubit, int, CounterEffect>(
      'emits [] and [LimitReachedEffect] when increment is called at max',
      build: () => CounterCubit(max: 3),
      seed: () => 3,
      act: (cubit) => cubit.increment(),
      expect: () => const <int>[],
      effects: () => const <CounterEffect>[LimitReachedEffect(3)],
    );

    blocWithEffectsTest<CounterCubit, int, CounterEffect>(
      'emits [1, 2] and two IncrementEffects when increment is called twice',
      build: CounterCubit.new,
      act: (cubit) => cubit
        ..increment()
        ..increment(),
      expect: () => const <int>[1, 2],
      effects: () => const <CounterEffect>[
        IncrementEffect(),
        IncrementEffect(),
      ],
    );
  });
}

void mainBloc() {
  group('CounterBloc', () {
    blocWithEffectsTest<CounterBloc, int, CounterEffect>(
      'emits [] and no effects when nothing is added',
      build: CounterBloc.new,
      expect: () => const <int>[],
      effects: () => const <CounterEffect>[],
    );

    blocWithEffectsTest<CounterBloc, int, CounterEffect>(
      'emits [1] and [IncrementEffect] when Increment is added',
      build: CounterBloc.new,
      act: (bloc) => bloc.add(const Increment()),
      expect: () => const <int>[1],
      effects: () => const <CounterEffect>[IncrementEffect()],
    );

    blocWithEffectsTest<CounterBloc, int, CounterEffect>(
      'emits [4] and [DecrementEffect] when Decrement is added with seed 5',
      build: CounterBloc.new,
      seed: () => 5,
      act: (bloc) => bloc.add(const Decrement()),
      expect: () => const <int>[4],
      effects: () => const <CounterEffect>[DecrementEffect()],
    );

    blocWithEffectsTest<CounterBloc, int, CounterEffect>(
      'emits [1, 2, 1] and mixed effects for mixed events',
      build: CounterBloc.new,
      act: (bloc) => bloc
        ..add(const Increment())
        ..add(const Increment())
        ..add(const Decrement()),
      expect: () => const <int>[1, 2, 1],
      effects: () => const <CounterEffect>[
        IncrementEffect(),
        IncrementEffect(),
        DecrementEffect(),
      ],
    );
  });
}

@immutable
abstract class CounterEffect {
  const CounterEffect();
}

@immutable
class IncrementEffect extends CounterEffect {
  const IncrementEffect();
}

@immutable
class DecrementEffect extends CounterEffect {
  const DecrementEffect();
}

@immutable
class LimitReachedEffect extends CounterEffect {
  const LimitReachedEffect(this.limit);
  final int limit;

  @override
  bool operator ==(Object other) =>
      other is LimitReachedEffect && other.limit == limit;

  @override
  int get hashCode => Object.hash(runtimeType, limit);
}

class CounterCubit extends CubitWithEffects<int, CounterEffect> {
  CounterCubit({this.max = 10}) : super(0);

  final int max;

  void increment() {
    if (state >= max) {
      emitEffect(LimitReachedEffect(max));
      return;
    }
    emit(state + 1);
    emitEffect(const IncrementEffect());
  }

  void decrement() {
    emit(state - 1);
    emitEffect(const DecrementEffect());
  }
}

abstract class CounterEvent {
  const CounterEvent();
}

class Increment extends CounterEvent {
  const Increment();
}

class Decrement extends CounterEvent {
  const Decrement();
}

class CounterBloc extends BlocWithEffects<CounterEvent, int, CounterEffect> {
  CounterBloc() : super(0) {
    on<Increment>(_onIncrement);
    on<Decrement>(_onDecrement);
  }

  void _onIncrement(Increment event, Emitter<int> emit) {
    emit(state + 1);
    emitEffect(const IncrementEffect());
  }

  void _onDecrement(Decrement event, Emitter<int> emit) {
    emit(state - 1);
    emitEffect(const DecrementEffect());
  }
}
