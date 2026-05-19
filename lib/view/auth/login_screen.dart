import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/auth_flow.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/user_role.dart';
import 'package:language_learning_app/provider/login_provider/login_provider_bloc.dart';
import 'package:language_learning_app/view/auth/otp_verification_screen.dart';
import 'package:language_learning_app/view/auth/signup_screen.dart';
import 'package:language_learning_app/view/auth/widgets/auth_form_card.dart';
import 'package:language_learning_app/view/auth/widgets/auth_screen_shell.dart';
import 'package:language_learning_app/view/auth/widgets/auth_text_field.dart';
import 'package:language_learning_app/view/auth/widgets/auth_primary_button.dart';
import 'package:language_learning_app/view/student/student_dashboard_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.language, required this.role});

  final AppLanguage language;
  final UserRole role;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _showErrors = false;
  final LoginProviderBloc _loginProviderBloc = LoginProviderBloc();
  String t(String key) => ConstString.text(widget.language, key);

  (String prefix, String cta) _splitQuestionCta(String fullText) {
    final qIndex = fullText.indexOf('?');
    if (qIndex == -1) return (fullText, '');
    final prefix = fullText.substring(0, qIndex + 1).trim();
    final cta = fullText.substring(qIndex + 1).trim();
    return (prefix, cta);
  }

  bool get _isEmailValid {
    final email = _emailController.text.trim();
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showSkipLogin = widget.role == UserRole.findTutor;

    return BlocProvider(
      create: (context) => _loginProviderBloc,
      child: Stack(
        children: [
          AuthScreenShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthScreenHeading(
                  title: t('welcomeBack'),
                  subtitle: t('emailOtpOnly'),
                ),
                const AuthHeadingSpacer(),
                AuthInputShell(
              child: AuthTextField(
                hint: t('email'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                dense: true,
                errorText: _showErrors && !_isEmailValid
                    ? t('invalidEmail')
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            BlocListener<LoginProviderBloc, LoginProviderState>(
              listener: (context, state) {
                if (state is LoginProviderInitial) {
                } else if (state is LoginProviderLoading) {
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) {
                      return Center(child: const CircularProgressIndicator());
                    },
                  );
                } else if (state is LoginProviderError) {
                  Navigator.pop(context);
                  commonAlertDialog(context, state.message);
                } else if (state is LoginProviderSuccess) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OtpVerificationScreen(
                        language: widget.language,
                        role: widget.role,
                        authFlow: AuthFlow.login,
                        email: _emailController.text.trim(),
                      ),
                    ),
                  );
                }
              },
              child: AuthPrimaryButton(
                text: t('sendOtp'),
                onPressed: () {
                  setState(() => _showErrors = true);
                  if (!_isEmailValid) return;
                  _loginProviderBloc.add(
                    LoginProvider(email: _emailController.text.trim()),
                  );
                },
              ),
            ),
            const SizedBox(height: ConstSize.grid * 3),
            Center(
              child: Builder(
                builder: (context) {
                  final fullText = t('dontHaveAccount');
                  final (prefix, cta) = _splitQuestionCta(fullText);
                  return Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '$prefix ',
                        style: TextStyle(
                          color: ConstColor.textSecondary.withValues(
                            alpha: 0.95,
                          ),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SignupScreen(
                                language: widget.language,
                                role: widget.role,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          cta.isNotEmpty ? cta : 'Sign Up',
                          style: const TextStyle(
                            color: ConstColor.primaryBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
          if (showSkipLogin)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 4,
              right: 8,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const StudentDashboardShell(
                        isGuest: true,
                      ),
                    ),
                  );
                },
                child: Text(
                  t('skipLogin'),
                  style: const TextStyle(
                    color: ConstColor.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
