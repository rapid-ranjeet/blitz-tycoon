import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/home_empire_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const BlitzTycoonApp());
}

class BlitzTycoonApp extends StatelessWidget {
  const BlitzTycoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blitz Tycoon: Unicorn Empire',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeEmpireScreen(),
    );
  }
}
