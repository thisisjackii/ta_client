import 'package:flutter/material.dart';
import 'package:ta_client/app/routes/routes.dart';

class CustomBottomNavbar extends StatelessWidget {
  const CustomBottomNavbar({
    required this.currentTab,
    required this.onTabSelected,
    super.key,
  });
  final int currentTab;
  final void Function(int) onTabSelected;

  @override
  Widget build(BuildContext context) {
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
                  final result = await Navigator.pushNamed(
                    context,
                    Routes.evaluationIntro,
                  );
                  // Do something with the result if needed
                  debugPrint('Returned from EvaluationIntro: $result');
                },
              ),
            ]),
            _buildTabItems([
              _TabItem(
                label: 'Budgeting',
                icon: Icons.attach_money_rounded,
                isSelected: currentTab == 2,
                onTap: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    Routes.budgetingIntro,
                  );
                  // Do something with the result if needed
                  debugPrint('Returned from BudgetingIntro: $result');
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
