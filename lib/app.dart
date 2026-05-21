import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'core/models/enums.dart';
import 'core/providers/app_mode_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/push_service.dart';

class AtrioApp extends ConsumerStatefulWidget {
  const AtrioApp({super.key});

  @override
  ConsumerState<AtrioApp> createState() => _AtrioAppState();
}

class _AtrioAppState extends ConsumerState<AtrioApp> {
  @override
  void initState() {
    super.initState();
    // Forward push-tap routes to the GoRouter. Done in initState so the
    // router is built once the first frame runs.
    PushService.onTapRoute = (route) {
      try {
        ref.read(routerProvider).go(route);
      } catch (_) {
        // Router not ready or invalid path — ignore.
      }
    };
  }

  @override
  Widget build(BuildContext context) {
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
