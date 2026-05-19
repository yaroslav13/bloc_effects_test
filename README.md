# bloc_effects_test

A testing library for [`bloc_effects`](https://pub.dev/packages/bloc_effects) that extends [`bloc_test`](https://pub.dev/packages/bloc_test) with **effect assertions**.

Enables testing of side-effects emitted by `BlocWithEffects` and `CubitWithEffects` using the familiar `blocTest` API.

## Installation

```yaml
dev_dependencies:
  bloc_effects_test: ^1.0.0
```

## Usage

```dart
blocWithEffectsTest<CounterCubit, int, CounterEffect>(
  'emits [1] and IncrementEffect when increment is called',
  build: CounterCubit.new,
  act: (cubit) => cubit.increment(),
  expect: () => [1],              // state assertions (as in blocTest)
  effects: () => [const IncrementEffect()],  // effect assertions (new)
);
```

### API

`blocWithEffectsTest` mirrors `blocTest` but adds two parameters:

- **`effects`** — `Function()` returning the expected effects (same as `expect` for states)
- **`skipEffects`** — skip leading effects (same as `skip` for states)

All other parameters work as in `blocTest`: `build`, `seed`, `act`, `expect`, `skip`, `wait`, `verify`, `errors`, `setUp`, `tearDown`, `tags`.

See [`example/main.dart`](example/main.dart) for comprehensive examples.
