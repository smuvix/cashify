import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smuvix_auth/application/providers/auth_providers.dart';
import 'package:smuvix_auth/presentation/widgets/auth_flow.dart';

import '../../features/accounts/domain/entities/account_entity.dart';
import '../../features/accounts/presentation/pages/account_form.dart';
import '../../features/budgets/domain/entities/budget_entity.dart';
import '../../features/budgets/presentation/pages/budget_details.dart';
import '../../features/budgets/presentation/pages/budget_form.dart';
import '../../features/categories/domain/entities/category_entity.dart';
import '../../features/categories/presentation/pages/category_form.dart';
import '../../features/dashboard/presentation/pages/dashboard.dart';
import '../../features/goals/domain/entities/goal_entity.dart';
import '../../features/goals/presentation/pages/goal_form.dart';
import '../../features/goals/presentation/pages/goals.dart';
import '../../features/budgets/presentation/pages/budgets.dart';
import '../../features/insights/presentation/pages/insights.dart';
import '../../features/transactions/domain/entities/transaction_entity.dart';
import '../../features/transactions/presentation/pages/transaction_form.dart';
import '../../features/transactions/presentation/pages/transactions.dart';
import '../../features/accounts/presentation/pages/accounts.dart';
import '../../features/categories/presentation/pages/categories.dart';
import '../../features/settings/presentation/pages/settings.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    refreshListenable: notifier,

    initialLocation: '/auth',

    routes: [
      GoRoute(path: '/auth', builder: (_, _) => const AuthFlow()),
      GoRoute(path: '/dashboard', builder: (_, _) => const DashboardPage()),

      GoRoute(
        path: '/budgets',
        builder: (_, _) => const BudgetsPage(),
        routes: [
          GoRoute(
            path: 'form',
            builder: (_, state) =>
                BudgetFormPage(budget: state.extra as BudgetEntity?),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                BudgetDetailsPage(budgetId: state.pathParameters['id']!),
          ),
        ],
      ),

      GoRoute(
        path: '/transactions',
        builder: (_, _) => const TransactionsPage(),
        routes: [
          GoRoute(
            path: 'form',
            builder: (_, state) => TransactionFormPage(
              transaction: state.extra as TransactionEntity?,
            ),
          ),
        ],
      ),

      GoRoute(
        path: '/goals',
        builder: (_, _) => const GoalsPage(),
        routes: [
          GoRoute(
            path: 'form',
            builder: (_, state) =>
                GoalFormPage(goal: state.extra as GoalEntity?),
          ),
        ],
      ),

      GoRoute(
        path: '/accounts',
        builder: (_, _) => const AccountsPage(),
        routes: [
          GoRoute(
            path: 'form',
            builder: (_, state) =>
                AccountFormPage(account: state.extra as AccountEntity?),
          ),
        ],
      ),

      GoRoute(
        path: '/categories',
        builder: (_, _) => const CategoriesPage(),
        routes: [
          GoRoute(
            path: 'form',
            builder: (_, state) =>
                CategoryFormPage(category: state.extra as CategoryEntity?),
          ),
        ],
      ),

      GoRoute(path: '/insights', builder: (_, _) => const InsightsPage()),
      GoRoute(path: '/settings', builder: (_, _) => const Settings()),
    ],

    redirect: (context, state) => notifier._redirect(state),
  );
});

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue>(currentUserProvider, (_, next) {
      if (!next.isLoading) {
        FlutterNativeSplash.remove();
      }
      notifyListeners();
    });
  }

  String? _redirect(GoRouterState state) {
    final authState = _ref.read(currentUserProvider);

    if (authState.isLoading || !authState.hasValue) {
      return null;
    }

    final user = authState.value;
    final isLoggedIn = user != null;

    final location = state.uri.toString();
    final isOnAuth = location == '/auth';

    if (!isLoggedIn && !isOnAuth) {
      return '/auth';
    }

    if (isLoggedIn && isOnAuth) {
      return '/dashboard';
    }

    return null;
  }
}
