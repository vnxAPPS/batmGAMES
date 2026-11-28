import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'light_screen.dart';
import 'theme.dart';
import 'torch.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  final torch = TorchController();
  await torch.init();
  runApp(VnxLightApp(torch: torch));
}

class VnxLightApp extends StatelessWidget {
  const VnxLightApp({super.key, required this.torch});

  final TorchController torch;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'vnxLIGHT',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      supportedLocales: const [Locale('en'), Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: LightScreen(torch: torch),
    );
  }
}
