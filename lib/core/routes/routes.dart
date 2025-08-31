
import 'package:bjj_dairy/core/routes/routes_names.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/log.dart';
import '../../presentation/view/add_goal_screen.dart';
import '../../presentation/view/add_log_screen.dart';
import '../../presentation/view/add_plan_screen.dart';
import '../../presentation/view/home_screen.dart';
import '../../presentation/view/log_history_screen.dart';
import '../../presentation/view/login_screen.dart';
import '../../presentation/view/plans_screen.dart';
import '../../presentation/view/profile_screen.dart';
import '../../presentation/view/search_folder_screen.dart';
import '../../presentation/view/sign_up_screen.dart';
import '../../presentation/view/splash_screen.dart';
import '../../presentation/view/voice_input_screen.dart';



class Routes {
  static Route<dynamic> generateRoutes(RouteSettings settings) {
    switch (settings.name) {
      case RoutesNames.splashScreen:
        return MaterialPageRoute(
            builder: (BuildContext context) => const SplashScreen());
      case RoutesNames.loginScreen:
        return MaterialPageRoute(
            builder: (BuildContext context) => LoginScreen());
      case RoutesNames.signupScreen:
        return MaterialPageRoute(
            builder: (BuildContext context) => SignUpScreen());
      case RoutesNames.homeScreen:
        return MaterialPageRoute(
            builder: (BuildContext context) => HomeScreen());
      case RoutesNames.addGoalScreen:
        return MaterialPageRoute(
            builder: (BuildContext context) => const AddGoalScreen());
      case RoutesNames.logHistoryScreen:
        return MaterialPageRoute(builder: (BuildContext context) {
          final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
          final Log log = args['log'] as Log; // Cast to Log
          return LogHistoryScreen(log:log);
        });
      case RoutesNames.addLogScreen:
        return MaterialPageRoute(
            builder: (BuildContext context) => const AddLogScreen());
      case RoutesNames.addPlanScreen:
        return MaterialPageRoute(
            builder: (BuildContext context) {
            final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
            final String parentId = args['parentId'] as String; // Cast to Log
            final bool isConnection = args['isConnection'] as bool;
            final String folderId = args['folderId'] as String;
            return AddPlanScreen(parentId:parentId,isConnection:isConnection,folderId: folderId,);
            });
      case RoutesNames.voiceInputScreen:
        return MaterialPageRoute(
            builder: (BuildContext context) => const VoiceInputScreen());
      case RoutesNames.plansScreen:
        return MaterialPageRoute(
            builder: (BuildContext context) => const PlansScreen());
      case RoutesNames.profileScreen:
        return MaterialPageRoute(
            builder: (BuildContext context) => const ProfileScreen());
      case RoutesNames.searchFolderScreen:
        return MaterialPageRoute(
            builder: (BuildContext context) => const SearchFolderScreen());
      default:
        return MaterialPageRoute(builder: (_) {
          return const Scaffold(
            body: Center(
              child: Text('No routes Defined'),
            ),
          );
        });
    }
  }
}
