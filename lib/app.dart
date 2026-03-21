import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'core/models/enums.dart';
import 'core/providers/app_mode_provider.dart';

class AtrioApp extends ConsumerWidget {
  const AtrioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final appMode = ref.watch(appModeProvider);

    return MaterialApp.router(
      title: 'Atrio',
      debugShowCheckedModeBanner: false,
      theme: appMode == AppMode.guest
          ? AtrioTheme.guestTheme
          : AtrioTheme.hostTheme,
      routerConfig: router,
    );
  }
}
