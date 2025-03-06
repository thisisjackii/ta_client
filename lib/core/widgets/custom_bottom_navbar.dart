import 'package:flutter/material.dart';

class CustomBottomNavbar extends StatelessWidget {
  const CustomBottomNavbar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });
  final int currentTab;
  final Function(int) onTabSelected;

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
                label: 'Tabung',
                icon: Icons.menu_book,
                isSelected: currentTab == 1,
                onTap: () => onTabSelected(1),
              ),
            ]),
            _buildTabItems([
              _TabItem(
                label: 'Stat',
                icon: Icons.insert_chart_rounded,
                isSelected: currentTab == 2,
                onTap: () => onTabSelected(2),
              ),
              _TabItem(
                label: 'Akun',
                icon: Icons.person_2_rounded,
                isSelected: currentTab == 3,
                onTap: () => onTabSelected(3),
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
