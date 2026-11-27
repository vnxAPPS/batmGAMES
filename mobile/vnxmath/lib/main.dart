import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'progress.dart';
import 'progress_scope.dart';
import 'puzzles/levels.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

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
  final prefs = await SharedPreferences.getInstance();
  runApp(VnxMathApp(progress: Progress(prefs, levels.length)));
}

class VnxMathApp extends StatelessWidget {
  const VnxMathApp({super.key, required this.progress});

  final Progress progress;

  @override
  Widget build(BuildContext context) {
    return ProgressScope(
      progress: progress,
      child: MaterialApp(
        title: 'vnxMATH',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        supportedLocales: const [Locale('en'), Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const HomeScreen(),
      ),
    );
  }
}
