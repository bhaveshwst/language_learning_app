import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/view/student/screens/student_home_dashboard_screen.dart';
import 'package:language_learning_app/view/student/screens/student_sessions_screen.dart';
import 'package:language_learning_app/view/student/screens/student_settings_screen.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';

class StudentDashboardShell extends StatefulWidget {
  const StudentDashboardShell({super.key});

  @override
  State<StudentDashboardShell> createState() => _StudentDashboardShellState();
}

class _StudentDashboardShellState extends State<StudentDashboardShell> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const StudentHomeDashboardScreen(),
      const StudentSessionsScreen(),
      const StudentSettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: pages[_selectedTab],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE8EDF7))),
          ),
          padding: const EdgeInsets.fromLTRB(
            ConstSize.grid,
            ConstSize.grid,
            ConstSize.grid,
            ConstSize.grid * 1.5,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                labelKey: 'home',
                selected: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
              _NavItem(
                icon: Icons.calendar_month_outlined,
                labelKey: 'sessions',
                selected: _selectedTab == 1,
                onTap: () => setState(() => _selectedTab = 1),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                labelKey: 'settings',
                selected: _selectedTab == 2,
                onTap: () => setState(() => _selectedTab = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.labelKey,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String labelKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: selected ? ConstColor.primaryBlue : ConstColor.textSecondary,
          ),
          const SizedBox(height: 4),
          AppText(
            labelKey,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? ConstColor.primaryBlue : ConstColor.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// Settings UI moved to `StudentSettingsScreen`.
