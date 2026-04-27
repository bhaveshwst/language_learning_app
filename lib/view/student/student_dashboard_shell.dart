import 'dart:developer';


import 'package:check_vpn_connection/check_vpn_connection.dart';
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

class _StudentDashboardShellState extends State<StudentDashboardShell> with WidgetsBindingObserver {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _checkVPNStatus();
  }

    AppLifecycleState? _appLifecycleState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
    switch (state) {
      case AppLifecycleState.resumed:
        log("AppLifecycleState.resumed");
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        log("AppLifecycleState.paused");
        break;
      case AppLifecycleState.detached:
        log("AppLifecycleState.detached");
        break;
      case AppLifecycleState.hidden:
        log("AppLifecycleState.hidden");
        break;
    }
  }

  bool isAppInBackground() {
    return _appLifecycleState != null &&
        _appLifecycleState == AppLifecycleState.paused;
  }

  Future<void> _checkVPNStatus() async {
    bool isVpnActive = await CheckVpnConnection.isVpnActive();
    if ( isVpnActive == true && isAppInBackground() == false) {
        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return WillPopScope(
              onWillPop: () async {
                return false;
              },
              child: const AlertDialog(
                title: Text(
                  "Alert!",
                  style: TextStyle(color: Colors.red),
                ),
                content: Text(
                  "VPN connections are not permitted within this network environment to ensure the security and integrity of our systems. Please close APP and dissconnect VPN.",
                ),
              ),
            );
          },
        );
      
    }
  }

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
              color: selected
                  ? ConstColor.primaryBlue
                  : ConstColor.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// Settings UI moved to `StudentSettingsScreen`.
