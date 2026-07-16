import 'package:go_router/go_router.dart';
import 'package:youbike/ui/screens/splash_screen.dart';
import 'package:youbike/ui/screens/welcome_page.dart';
import 'package:youbike/ui/screens/permission_handler_page.dart';
import 'package:youbike/ui/widgets/app_wrapper.dart';
import 'package:youbike/ui/screens/home_screen.dart';
import 'package:youbike/ui/screens/settings_screen.dart';
import 'package:youbike/ui/screens/theme_selection_screen.dart';
import 'package:youbike/ui/screens/region_selection_screen.dart';
import 'package:youbike/ui/screens/language_selection_screen.dart';
import 'package:youbike/ui/screens/app_log_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/permission',
        builder: (context, state) => const PermissionHandlerPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const AppWrapper(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/theme-selection',
        builder: (context, state) => const ThemeSelectionScreen(),
      ),
      GoRoute(
        path: '/region-selection',
        builder: (context, state) => const RegionSelectionScreen(),
      ),
      GoRoute(
        path: '/language-selection',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: '/app-logs',
        builder: (context, state) => const AppLogPage(),
      ),
    ],
    errorBuilder: (context, state) => const HomeScreen(),
  );
}
