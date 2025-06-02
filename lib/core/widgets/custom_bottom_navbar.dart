import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/services/first_launch_service.dart';
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/core/state/auth_state.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/repositories/budgeting_repository.dart';
import 'package:ta_client/features/evaluation/repositories/evaluation_repository.dart';

class CustomBottomNavbar extends StatelessWidget {
  const CustomBottomNavbar({
    required this.currentTab,
    required this.onTabSelected,
    super.key,
  });
  final int currentTab;
  final void Function(int) onTabSelected;

  // Helper function to check if user has any budget plans
  Future<bool> _userHasAnyBudgetPlans() async {
    // Renamed for clarity
    final authState = sl<AuthState>();
    if (!authState.isAuthenticated || authState.currentUser == null) {
      return false;
    }
    try {
      final budgetingRepo = sl<BudgetingRepository>();
      // Fetch ALL plans for the user. This method needs to be robust.
      final plans = await budgetingRepo.getBudgetPlansForUser(
        authState.currentUser!.id,
      );
      return plans.isNotEmpty;
    } catch (e) {
      debugPrint(
        '[CustomBottomNavbar] Error checking for any budget plans: $e',
      );
      return false;
    }
  }

  // Helper function to check if user has any evaluation history
  Future<bool> _userHasEvaluationHistory() async {
    final authState = sl<AuthState>();
    if (!authState.isAuthenticated || authState.currentUser == null) {
      return false;
    }
    try {
      final evaluationRepo = sl<EvaluationRepository>();
      final history = await evaluationRepo
          .getEvaluationHistory(); // Fetches all history for current user
      return history.isNotEmpty;
    } catch (e) {
      debugPrint(
        '[CustomBottomNavbar] Error checking for evaluation history: $e',
      );
      return false; // Assume no history on error
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstLaunchService = sl<FirstLaunchService>();
    return BottomAppBar(
      color: const Color(0xffCAE2F7),
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _buildTabItems([
              _TabItem(
                label: 'Home',
                icon: Icons.dashboard,
                isSelected: currentTab == 0,
                onTap: () => onTabSelected(0),
              ),
              _TabItem(
                label: 'Evaluasi',
                icon: Icons.saved_search_rounded,
                isSelected: currentTab == 1,
                onTap: () async {
                  final introSeen = await firstLaunchService
                      .isEvaluationIntroSeen();
                  final hasHistory =
                      await _userHasEvaluationHistory(); // Check for existing data

                  if (!introSeen || !hasHistory) {
                    // If intro not seen OR no history exists
                    if (context.mounted) {
                      await Navigator.pushNamed(
                        context,
                        Routes.evaluationIntro,
                      );
                    }
                  } else {
                    // User has seen intro AND has history, go directly to a sensible "dashboard" or "date selection"
                    // If EvaluationDashboardPage is empty without selected dates, EValuationDatePage is better.
                    if (context.mounted) {
                      await Navigator.pushNamed(
                        context,
                        Routes.evaluationDateSelection,
                      );
                    }
                  }
                },
              ),
            ]),
            _buildTabItems([
              _TabItem(
                label: 'Budgeting',
                icon: Icons.attach_money_rounded,
                isSelected: currentTab == 2,
                onTap: () async {
                  final hasPlans =
                      await _userHasAnyBudgetPlans(); // Check for ANY plan
                  final introSeen = await firstLaunchService
                      .isBudgetingIntroSeen();

                  if (hasPlans) {
                    // User has existing plans, go directly to dashboard
                    // BudgetingDashboard's initState will load the latest/default plan
                    if (context.mounted) {
                      // Ensure BLoC loads existing plans if navigating directly
                      context.read<BudgetingBloc>().add(
                        BudgetingLoadUserPlans(),
                      );
                      await Navigator.pushNamed(
                        context,
                        Routes.budgetingDashboard,
                      );
                    }
                  } else if (introSeen) {
                    // No plans, but intro has been seen, go to start of creation flow
                    if (context.mounted) {
                      context.read<BudgetingBloc>().add(
                        BudgetingResetState(),
                      ); // Reset for new plan
                      await Navigator.pushNamed(
                        context,
                        Routes.budgetingIncomeDate,
                      );
                    }
                  } else {
                    // No plans, intro not seen, go to intro page
                    if (context.mounted) {
                      await Navigator.pushNamed(context, Routes.budgetingIntro);
                    }
                  }
                },
              ),
              _TabItem(
                label: 'Akun',
                icon: Icons.person_2_rounded,
                isSelected: currentTab == 3,
                onTap: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    Routes.profilePage,
                  );
                  // Do something with the result if needed
                  debugPrint('Returned from Profile Page: $result');
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItems(List<_TabItem> items) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => SizedBox(
              width: 65,
              child: MaterialButton(
                onPressed: item.onTap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: item.isSelected
                          ? const Color(0xff1D3B5A)
                          : Colors.blueGrey,
                    ),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontVariations: const [FontVariation('wght', 500)],
                        color: item.isSelected
                            ? const Color(0xff1D3B5A)
                            : Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TabItem {
  _TabItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
}
