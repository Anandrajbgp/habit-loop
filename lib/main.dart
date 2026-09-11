import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'screens/habit_list_screen.dart';
import 'services/app_update_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HabitLoopApp());
}

// Simple Theme Manager using ValueNotifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

class HabitLoopApp extends StatefulWidget {
  const HabitLoopApp({super.key});

  @override
  State<HabitLoopApp> createState() => _HabitLoopAppState();
}

class _HabitLoopAppState extends State<HabitLoopApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _updateDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForAppUpdate();
    });
  }

  Future<void> _checkForAppUpdate() async {
    try {
      final AppUpdateInfo? updateInfo = await AppUpdateService.checkForUpdate();
      if (updateInfo == null || _updateDialogShown) {
        return;
      }

      final BuildContext? context = _navigatorKey.currentContext;
      if (context == null || !context.mounted) {
        return;
      }

      _updateDialogShown = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: !updateInfo.forceUpdate,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(updateInfo.title),
            content: Text(updateInfo.message),
            actions: <Widget>[
              if (!updateInfo.forceUpdate)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Later'),
                ),
              ElevatedButton(
                onPressed: () async {
                  final Uri uri = Uri.parse(updateInfo.downloadUrl);
                  if (uri.scheme.toLowerCase() != 'https') {
                    return;
                  }
                  await launchUrl(uri, mode: LaunchMode.platformDefault);
                  if (!dialogContext.mounted) {
                    return;
                  }
                  if (!updateInfo.forceUpdate) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      );
    } catch (_) {
      // Silently ignore update check failures to avoid blocking app launch.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'HabitLoop',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          // Premium Light Theme (Golden/Creamy)
          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFB8860B), // Golden Rod
              brightness: Brightness.light,
              surface: const Color(0xFFFFF9E6), // Soft Golden Light
            ),
            scaffoldBackgroundColor: const Color(0xFFFFFDF5),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: Color(0xFF432C0B),
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
              iconTheme: IconThemeData(color: Color(0xFF432C0B)),
            ),
          ),
          // Premium Dark Theme (Soft Dark, not pure black)
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6200EE),
              brightness: Brightness.dark,
              surface: const Color(0xFF1E1E1E), // Soft Dark Surface
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
              iconTheme: IconThemeData(color: Colors.white),
            ),
          ),
          home: const HabitListScreen(),
        );
      },
    );
  }
}
