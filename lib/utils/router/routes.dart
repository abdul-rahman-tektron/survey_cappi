import 'dart:ui';

// Auth
import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/sp_model.dart';
import 'package:srpf/screens/auth/login/login_screen.dart';
import 'package:srpf/screens/common/error_screen.dart';
import 'package:srpf/screens/common/home/home_screen.dart';
import 'package:srpf/screens/common/network_error_screen.dart';
import 'package:srpf/screens/common/survey_list/survey_list_screen.dart';
import 'package:srpf/screens/questionnaire/flows/stated_preference/stated_preference_notifier.dart';
import 'package:srpf/screens/questionnaire/questionnaire_home.dart';
import 'package:srpf/screens/questionnaire/sp_home_screen.dart';
import 'package:srpf/screens/questionnaire/sp_survey_screen.dart';
import 'package:srpf/utils/enums.dart';

import '../../screens/questionnaire/questionnaire_screen.dart';

class AppRoutes {
  /// 🔐 Auth
  static const String login = '/login';
  static const String home = '/home';
  static const String questionnaireHome = '/questionnaire-home';
  static const String questionnaire = '/questionnaire';
  static const String surveyList = '/survey-list';
  static const String statedPreferencePreamble = '/sp-preamble';
  static const String statedPreference = '/stated-reference';

  /// 🌐 Common
  static const String mapLocation = '/map-location';

  /// ❗ Error
  static const String networkError = '/network-error';
  static const String notFound = '/not-found';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    Widget screen;

    switch (settings.name) {
      // 🔐 Auth
      case AppRoutes.login:
        screen = LoginScreen();
        break;

      case AppRoutes.home:
        screen = HomeScreen();
        break;
      case AppRoutes.statedPreference:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final sets = args['sets'] as List<SpSet>?;
        final int? interviewMasterId = args['interviewMasterId'] as int?;
        final int continuedElapsedSec = args['continuedElapsedSec'] as int? ?? 0;
        final String? startedIso = args['startedIso'] as String?;
        screen = SpSurveyScreen(
          initialSets: sets ?? mockLoadSixSets(),
          interviewMasterId: interviewMasterId,
          continuedElapsedSec: continuedElapsedSec,
          startedIso: startedIso,
        ); // fallback
        break;

      case AppRoutes.questionnaireHome:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final questionnaireType = args['questionnaireType'] as QuestionnaireType?;
        final int? editRsiId = args['editRsiId'] as int?;
        screen = QuestionnaireHome(questionnaireType: questionnaireType, editRsiId: editRsiId);
        break;

      case AppRoutes.questionnaire:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final questionnaireType = args['questionnaireType'] as QuestionnaireType?;
        final int? editRsiId = args['editRsiId'] as int?;
        screen = QuestionnaireScreen(questionnaireType: questionnaireType, editRsiId: editRsiId);
        break;

      case AppRoutes.statedPreferencePreamble:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final String od = args['od'] as String? ?? 'Origin to Destination';
        final List<SpSet>? sets = args['sets'] as List<SpSet>?;
        final int? interviewMasterId = args['interviewMasterId'] as int?;
        final int continuedElapsedSec = args['continuedElapsedSec'] as int? ?? 0;
        final String? startedIso = args['startedIso'] as String?;

        screen = Builder(
          builder: (context) => SpPreambleScreen(
            odResponse: od,
            initialSets: sets ?? mockLoadSixSets(),
            interviewMasterId: interviewMasterId,
            continuedElapsedSec: continuedElapsedSec,
            startedIso: startedIso,
          ),
        );
        break;

      case AppRoutes.surveyList:
        screen = SurveyListScreen();
        break;

      // ❗ Error
      case AppRoutes.networkError:
        screen = const NetworkErrorScreen();
        break;

      // Default
      default:
        screen = const NotFoundScreen();
    }

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, animation, __) => screen,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child); // no BackdropFilter
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

Widget defaultPageTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: animation,
    child: BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: (1 - animation.value) * 5,
        sigmaY: (1 - animation.value) * 5,
      ),
      child: child,
    ),
  );
}
