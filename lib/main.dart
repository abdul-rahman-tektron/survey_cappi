// lib/main.dart
import 'dart:async';
import 'dart:math' show sqrt, pow;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:srpf/utils/helpers/app_crash_report.dart';
import 'package:toastification/toastification.dart';

import 'package:srpf/core/generated_locales/l10n.dart';
import 'package:srpf/core/notifier/language_notifier.dart';
import 'package:srpf/screens/auth/login/login_screen.dart';
import 'package:srpf/screens/common/home/home_screen.dart';
import 'package:srpf/utils/helpers/screen_size.dart';
import 'package:srpf/utils/router/routes.dart';
import 'package:srpf/res/themes.dart';

import 'package:srpf/utils/app_initializer.dart';

void main() {
  // Optional: make zone errors fatal (must be set BEFORE bindings init)
  BindingBase.debugZoneErrorsAreFatal = true;

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized(); // <-- now in the SAME zone as runApp

    // Firebase first
    await Firebase.initializeApp();

    // Crash reporter
    await AppCrashReporter.init();

    // App init + user context
    await AppInitializer.initialize();
    final userData = await AppInitializer.loadUserData();
    final String? token = userData["token"] as String?;
    final uid = (userData['userId'] ?? '').toString();
    final uname = (userData['userName'] ?? '').toString();
    if (uid.isNotEmpty) {
      await AppCrashReporter.setUser(userId: uid, name: uname);
    }

    // Route all Flutter errors to crash reporter too
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);

      // Use a fallback empty stack trace if it's null
      final stack = details.stack ?? StackTrace.empty;

      AppCrashReporter.recordError(details.exception, stack, fatal: false);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      AppCrashReporter.recordError(error, stack, fatal: true);
      return true;
    };

    runApp(MyApp(token: token)); // <-- same zone as ensureInitialized
  }, (error, stack) {
    // Unhandled async errors
    AppCrashReporter.recordError(error, stack, fatal: true);
  });
}

class MyApp extends StatelessWidget {
  final String? token;
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  const MyApp({super.key, this.token});

  @override
  Widget build(BuildContext context) => AppWrapper(token: token);
}

class AppWrapper extends StatelessWidget {
  final String? token;
  const AppWrapper({super.key, this.token});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageNotifier()),
      ],
      child: Builder(
        builder: (context) {
          final lang = context.watch<LanguageNotifier>().locale;
          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            child: ToastificationWrapper(
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                navigatorKey: MyApp.navigatorKey,
                title: 'Xception',
                locale: lang,
                supportedLocales: const [Locale('en'), Locale('ar')],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                onGenerateRoute: AppRouter.onGenerateRoute,
                home: _getInitialScreen(token),
                theme: AppThemes.lightTheme(languageCode: lang.languageCode),
                builder: (context, child) {
                  ScreenSize.init(context);
                  final mq = MediaQuery.of(context);

                  // ✅ Calculate screen size in inches
                  final size = mq.size; // logical pixels
                  final pixelRatio = mq.devicePixelRatio;
                  final widthPx = size.width * pixelRatio;
                  final heightPx = size.height * pixelRatio;

                  final dpi = mq.devicePixelRatio * 160; // base density
                  final widthInches = widthPx / dpi;
                  final heightInches = heightPx / dpi;

                  final screenInches = sqrt(
                    pow(widthInches, 2) + pow(heightInches, 2),
                  ).toStringAsFixed(2);

                  debugPrint('📏 Screen size: $screenInches inches '
                      '(${widthInches.toStringAsFixed(2)} x ${heightInches.toStringAsFixed(2)})');

                  final textScale = pixelRatio > 3.0 ? 0.8 : 1.0;
                  return MediaQuery(
                    data: mq.copyWith(textScaleFactor: textScale),
                    child: child!,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getInitialScreen(String? token) {
    return token != null ? HomeScreen() : const LoginScreen();
  }
}