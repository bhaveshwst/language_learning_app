import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/auth_flow.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/user_role.dart';
import 'package:language_learning_app/core/widgets/app_dropdown_button2.dart';
import 'package:language_learning_app/provider/sign_up_provider/signup_bloc.dart';
import 'package:language_learning_app/view/auth/otp_verification_screen.dart';
import 'package:language_learning_app/view/auth/widgets/auth_primary_button.dart';
import 'package:language_learning_app/view/auth/widgets/auth_screen_shell.dart';
import 'package:language_learning_app/view/auth/widgets/auth_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.language, required this.role});

  final AppLanguage language;
  final UserRole role;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  String? _country;
  final TextEditingController _emailController = TextEditingController();
  final bool _showErrors = false;
  int? _selectedYear;

  final SignupBloc _signupBloc = SignupBloc();

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
    final bool isUs = (_country ?? 'us') == 'us';
    return BlocProvider(
      create: (context) => _signupBloc,
      child: AuthScreenShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('createAccount'),
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: ConstSize.grid * 3),
            AppDropdownButton2<String>(
              hintText: t('country'),
              value: _country,
              items: const ['us', 'kr'],
              itemLabelBuilder: (v) =>
                  v == 'us' ? t('unitedStates') : t('southKorea'),
              onChanged: (v) => setState(() => _country = v),
            ),
            const SizedBox(height: ConstSize.grid * 1),
            Text(
              isUs ? t('usEduRule') : t('krDomainRule'),
              style: const TextStyle(
                color: ConstColor.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: ConstSize.grid * 2),
            AuthTextField(
              hint: t('schoolEmail'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              errorText: _showErrors && !_isEmailValid
                  ? t('invalidEmail')
                  : null,
            ),
            // const SizedBox(height: ConstSize.grid),
            // Text(
            //   t('ageTitle'),
            //   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            // ),
            const SizedBox(height: 20),
            AppDropdownButton2<int>(
              hintText: t('birthYear'),
              value: _selectedYear,
              items: List.generate(14, (index) => 2012 - index),
              itemLabelBuilder: (year) => '$year',
              onChanged: (year) => setState(() => _selectedYear = year),
            ),
            const SizedBox(height: ConstSize.grid * 1),
            Text(
              t('ageRule'),
              style: const TextStyle(
                color: ConstColor.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: ConstSize.grid * 2),
            BlocListener<SignupBloc, SignupState>(
              listener: (context, state) {
                if (state is SignupInitial) {
                } else if (state is SignupLoading) {
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) {
                      return Center(child: const CircularProgressIndicator());
                    },
                  );
                } else if (state is SignupError) {
                  Navigator.pop(context);
                  commonAlertDialog(context, state.message);
                }
                else if (state is SignupSuccess) {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OtpVerificationScreen(
                          language: widget.language,
                          role: widget.role,
                          authFlow: AuthFlow.signup,
                          email: _emailController.text.trim(),
                        ),
                      ),
                    );
                }
              },
              child: AuthPrimaryButton(
                text: t('sendOtp'),
                onPressed: () {
                  if (_country == null) {
                    commonAlertDialog(context, t('selectCountryError'));
                  } else if (_emailController.text.trim().isEmpty) {
                    commonAlertDialog(context, t('enterEmailAddressError'));
                  } else if (!_isEmailValid) {
                    commonAlertDialog(context, t('invalidEmail'));
                  } else if (_selectedYear == null) {
                    commonAlertDialog(context, t('selectBirthYearError'));
                  } else {
                    _signupBloc.add(
                      SignupProvider(
                        email: _emailController.text.trim(),
                        country: _country?.toLowerCase().toString() == "us" ? "US" : "KR",
                        birthyear: _selectedYear?.toString() ?? '',
                        userrole: widget.role.name.toLowerCase().toString() == 'findtutor' ? 'student' : 'tutor',
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: ConstSize.grid * 3),
            Center(
              child: Builder(
                builder: (context) {
                  final fullText = t('alreadyHaveAccount');
                  final (prefix, cta) = _splitQuestionCta(fullText);
                  return Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '$prefix ',
                        style: const TextStyle(
                          color: ConstColor.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          cta.isNotEmpty ? cta : 'Login',
                          style: const TextStyle(
                            color: ConstColor.primaryBlue,
                            fontWeight: FontWeight.w600,
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
    );
  }
}
