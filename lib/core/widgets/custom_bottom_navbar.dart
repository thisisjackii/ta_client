import 'package:flutter/material.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/services/first_launch_service.dart';
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/core/state/auth_state.dart';
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
  Future<bool> _userHasBudgetPlans() async {
    final authState = sl<AuthState>();
    if (!authState.isAuthenticated || authState.currentUser == null) {
      return false;
    }
    // Note: BudgetingRepository.getBudgetPlansForUser now needs to be accessible.
    // It might not be directly registered in GetIt.
    // For simplicity, let's assume we can get an instance or use a specific GetIt registration for it.
    // If BudgetingRepository itself isn't in GetIt, but its service is, you might need to add a repo getter.
    // OR, add a method to BudgetingService that the repo uses, and the service calls the backend.
    // For now, assuming BudgetingRepository is in GetIt or can be easily fetched.
    try {
      final budgetingRepo = sl<BudgetingRepository>();
      final plans = await budgetingRepo.getBudgetPlansForUser(
        authState.currentUser!.id,
      ); // Fetch ALL plans
      return plans.isNotEmpty;
    } catch (e) {
      debugPrint('[CustomBottomNavbar] Error checking for budget plans: $e');
      return false; // Assume no plans on error
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
                  final introSeen = await firstLaunchService
                      .isBudgetingIntroSeen();
                  final hasPlans = await _userHasBudgetPlans();

                  if (!introSeen || !hasPlans) {
                    // If intro not seen OR no plans exist
                    if (context.mounted) {
                      await Navigator.pushNamed(context, Routes.budgetingIntro);
                    }
                  } else {
                    // User has seen intro AND has plans, go directly to budgeting dashboard
                    // The BudgetingDashboard will need logic to load the latest/relevant plan
                    // or prompt user if multiple plans exist.
                    if (context.mounted) {
                      await Navigator.pushNamed(
                        context,
                        Routes.budgetingDashboard,
                      );
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
