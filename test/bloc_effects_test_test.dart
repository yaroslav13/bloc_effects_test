import 'package:bloc/bloc.dart' show Emitter;
import 'package:bloc_effects/bloc_effects.dart';
import 'package:bloc_effects_test/bloc_effects_test.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

@immutable
abstract class CounterEffect {
  const CounterEffect();
}

@immutable
class IncrementEffect extends CounterEffect {
  const IncrementEffect();

  @override
  bool operator ==(Object other) => other is IncrementEffect;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'IncrementEffect()';
}

@immutable
class DecrementEffect extends CounterEffect {
  const DecrementEffect();

  @override
  bool operator ==(Object other) => other is DecrementEffect;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'DecrementEffect()';
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

  @override
  String toString() => 'LimitReachedEffect($limit)';
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
    if (state <= 0) {
      emitEffect(const LimitReachedEffect(0));
      return;
    }
    emit(state - 1);
    emitEffect(const DecrementEffect());
  }
}

abstract class CounterEvent {
  const CounterEvent();
}

class IncrementEvent extends CounterEvent {
  const IncrementEvent();
}

class DecrementEvent extends CounterEvent {
  const DecrementEvent();
}

class CounterBloc extends BlocWithEffects<CounterEvent, int, CounterEffect> {
  CounterBloc() : super(0) {
    on<IncrementEvent>(_onIncrement);
    on<DecrementEvent>(_onDecrement);
  }

  void _onIncrement(IncrementEvent event, Emitter<int> emit) {
    emit(state + 1);
    emitEffect(const IncrementEffect());
  }

  void _onDecrement(DecrementEvent event, Emitter<int> emit) {
    emit(state - 1);
    emitEffect(const DecrementEffect());
  }
}

void main() {
  group('CubitWithEffects', () {
    blocWithEffectsTest<CounterCubit, int, CounterEffect>(
      'emits IncrementEffect when increment is called',
      build: CounterCubit.new,
      act: (cubit) => cubit.increment(),
      expect: () => [1],
      effects: () => [const IncrementEffect()],
    );

    blocWithEffectsTest<CounterCubit, int, CounterEffect>(
      'emits DecrementEffect when decrement is called from positive state',
      build: CounterCubit.new,
      seed: () => 3,
      act: (cubit) => cubit.decrement(),
      expect: () => [2],
      effects: () => [const DecrementEffect()],
    );

    blocWithEffectsTest<CounterCubit, int, CounterEffect>(
      'emits LimitReachedEffect at max with no state change',
      build: () => CounterCubit(max: 5),
      seed: () => 5,
      act: (cubit) => cubit.increment(),
      expect: () => <int>[],
      effects: () => [const LimitReachedEffect(5)],
    );

    blocWithEffectsTest<CounterCubit, int, CounterEffect>(
      'emits LimitReachedEffect at zero with no state change',
      build: CounterCubit.new,
      act: (cubit) => cubit.decrement(),
      expect: () => <int>[],
      effects: () => [const LimitReachedEffect(0)],
    );

    blocWithEffectsTest<CounterCubit, int, CounterEffect>(
      'emits two IncrementEffects after two increments',
      build: CounterCubit.new,
      act: (cubit) {
        cubit
          ..increment()
          ..increment();
      },
      expect: () => [1, 2],
      effects: () => [const IncrementEffect(), const IncrementEffect()],
    );

    blocWithEffectsTest<CounterCubit, int, CounterEffect>(
      'emits no effects when no action is taken',
      build: CounterCubit.new,
      expect: () => <int>[],
      effects: () => <CounterEffect>[],
    );

    blocWithEffectsTest<CounterCubit, int, CounterEffect>(
      'skipEffects skips the first emitted effect',
      build: CounterCubit.new,
      act: (cubit) {
        cubit
          ..increment()
          ..increment();
      },
      skipEffects: 1,
      expect: () => [1, 2],
      effects: () => [const IncrementEffect()],
    );

    blocWithEffectsTest<CounterCubit, int, CounterEffect>(
      'verify is called after assertions',
      build: CounterCubit.new,
      act: (cubit) => cubit.increment(),
      expect: () => [1],
      effects: () => [const IncrementEffect()],
      verify: (cubit) => expect(cubit.state, equals(1)),
    );
  });

  group('BlocWithEffects', () {
    blocWithEffectsTest<CounterBloc, int, CounterEffect>(
      'emits IncrementEffect when IncrementEvent is added',
      build: CounterBloc.new,
      act: (bloc) => bloc.add(const IncrementEvent()),
      expect: () => [1],
      effects: () => [const IncrementEffect()],
    );

    blocWithEffectsTest<CounterBloc, int, CounterEffect>(
      'emits DecrementEffect when DecrementEvent is added',
      build: CounterBloc.new,
      seed: () => 5,
      act: (bloc) => bloc.add(const DecrementEvent()),
      expect: () => [4],
      effects: () => [const DecrementEffect()],
    );

    blocWithEffectsTest<CounterBloc, int, CounterEffect>(
      'emits Increment and Decrement effects for mixed events',
      build: CounterBloc.new,
      act: (bloc) {
        bloc
          ..add(const IncrementEvent())
          ..add(const IncrementEvent())
          ..add(const DecrementEvent());
      },
      expect: () => [1, 2, 1],
      effects: () => [
        const IncrementEffect(),
        const IncrementEffect(),
        const DecrementEffect(),
      ],
    );
  });
}
