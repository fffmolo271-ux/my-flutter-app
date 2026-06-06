import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/bootstrap.dart' as bootstrap;
import 'app/core_state.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final config = await bootstrap.initializeApp();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
        Locale('hi'),
        Locale('es'),
        Locale('fr'),
        Locale('pt'),
        Locale('ru'),
        Locale('ur'),
        Locale('id'),
        Locale('de'),
        Locale('ja'),
      ],
      path: 'assets/l10n',
      useOnlyLangCode: true,
      startLocale: const Locale('en'),
      child: ChangeNotifierProvider(
        create: (_) => CoreState(config.firebaseEnabled),
        child: const App(),
      ),
    ),
  );
}



