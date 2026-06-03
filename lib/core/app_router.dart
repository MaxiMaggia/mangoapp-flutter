import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/category_form_screen.dart';
import '../presentation/screens/category_list_screen.dart';
import '../presentation/screens/dolar_rates_screen.dart';
import '../presentation/screens/expense_details_screen.dart';
import '../presentation/screens/expense_form_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/main_shell.dart';
import '../presentation/screens/profile_screen.dart';
import '../presentation/screens/register_screen.dart';
import '../presentation/screens/statistics_screen.dart';
import '../presentation/viewmodels/providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Pequeño helper para que GoRouter se entere de los cambios de auth
/// y dispare el redirect.
class _AuthRefreshListener extends ChangeNotifier {
  _AuthRefreshListener(Ref ref) {
    ref.listen(authViewModelProvider, (_, __) => notifyListeners());
  }
}

final _authRefreshProvider = Provider<_AuthRefreshListener>(
  (ref) => _AuthRefreshListener(ref),
);

/// Router de la app.
///
/// Usa StatefulShellRoute.indexedStack para mantener un BottomNavigationBar
/// con tres tabs (Home / Estadisticas / Perfil) que conservan su estado al
/// alternar entre ellas.
///
/// El redirect lee el AuthNotifier para decidir si llevar al usuario al login
/// o al home segun haya sesion iniciada. Reacciona a cambios via
/// refreshListenable.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_authRefreshProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authViewModelProvider);
      final loggedIn = auth.user != null;

      final goingToAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Sin sesion no te dejamos entrar a nada que no sea login/registro...
      if (!loggedIn && !goingToAuth) return '/login';
      // ...y si ya estas logueado, no te dejamos volver al login.
      if (loggedIn && goingToAuth) return '/home';
      return null; // todo ok, seguis donde ibas
    },
    routes: [
      GoRoute(
        path: '/login',
        name: LoginScreen.name,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: RegisterScreen.name,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Shell con bottom navbar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                name: HomeScreen.name,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                name: StatisticsScreen.name,
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: ProfileScreen.name,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Rutas push (sin navbar)
      GoRoute(
        path: '/expense/new',
        name: ExpenseFormScreen.nameNew,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExpenseFormScreen(),
      ),
      GoRoute(
        path: '/expense/:id',
        name: ExpenseDetailsScreen.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ExpenseDetailsScreen(expenseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/expense/:id/edit',
        name: ExpenseFormScreen.nameEdit,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ExpenseFormScreen(expenseId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/categories',
        name: CategoryListScreen.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoryListScreen(),
      ),
      GoRoute(
        path: '/categories/new',
        name: CategoryFormScreen.nameNew,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoryFormScreen(),
      ),
      GoRoute(
        path: '/categories/:id/edit',
        name: CategoryFormScreen.nameEdit,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            CategoryFormScreen(categoryId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/dolar-rates',
        name: DolarRatesScreen.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DolarRatesScreen(),
      ),
    ],
  );
});
