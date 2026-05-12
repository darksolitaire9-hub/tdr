import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'focus_provider.g.dart';

@riverpod
class DailyFocus extends _$DailyFocus {
  @override
  bool build() => false;

  void toggle() => state = !state;
}
