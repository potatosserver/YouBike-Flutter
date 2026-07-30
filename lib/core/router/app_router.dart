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
import 'package:youbike/ui/screens/beta_features_screen.dart';

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
        builder: (context, state) => const PermissionHandlerPage(
          type: PermissionType.location,
        ),
      ),
      GoRoute(
        path: '/permission/notification',
        builder: (context, state) => const PermissionHandlerPage(
          type: PermissionType.notification,
        ),
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
        path: '/beta-features',
        builder: (context, state) => const BetaFeaturesScreen(),
      ),
    ],
    errorBuilder: (context, state) => const HomeScreen(),
  );
}
