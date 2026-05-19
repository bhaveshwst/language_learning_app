import 'package:flutter/material.dart';
import 'package:language_learning_app/core/auth/student_auth_gate.dart';
import 'package:language_learning_app/view/student/student_dashboard_shell.dart';

/// Lands on the student dashboard, then opens [BookingScreen] when login
/// was triggered from a guest booking attempt.
class StudentResumeBookingHost extends StatefulWidget {
  const StudentResumeBookingHost({super.key});

  @override
  State<StudentResumeBookingHost> createState() =>
      _StudentResumeBookingHostState();
}

class _StudentResumeBookingHostState extends State<StudentResumeBookingHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      StudentAuthGate.resumePendingBookingIfAny(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const StudentDashboardShell();
  }
}
