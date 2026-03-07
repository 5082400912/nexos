import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'theme/nexos_theme.dart';
import 'screens/boot/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Hive.initFlutter();
  await Hive.openBox('calculator_history');
  await Hive.openBox('nexos_prefs');

  runApp(const NexOSApp());
}

class NexOSApp extends StatelessWidget {
  const NexOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexOS',
      debugShowCheckedModeBanner: false,
      theme: NexOSTheme.theme,
      home: const SplashScreen(),
    );
  }
}
