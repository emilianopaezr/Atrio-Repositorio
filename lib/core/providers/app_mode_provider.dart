import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums.dart';

final appModeProvider = NotifierProvider<AppModeNotifier, AppMode>(
  AppModeNotifier.new,
);

class AppModeNotifier extends Notifier<AppMode> {
  @override
  AppMode build() => AppMode.guest;

  void switchToGuest() => state = AppMode.guest;
  void switchToHost() => state = AppMode.host;
  void toggle() => state = state == AppMode.guest ? AppMode.host : AppMode.guest;
}
