import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'core/models/enums.dart';
import 'core/providers/app_mode_provider.dart';
import 'core/providers/locale_provider.dart';

class AtrioApp extends ConsumerWidget {
  const AtrioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final appMode = ref.watch(appModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Atrio',
      debugShowCheckedModeBanner: false,
      theme: appMode == AppMode.guest
          ? AtrioTheme.guestTheme
          : AtrioTheme.hostTheme,
      routerConfig: router,
      locale: locale,
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
