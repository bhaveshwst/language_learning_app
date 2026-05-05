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

  String _countryToApiCode(String? country) {
    switch ((country ?? '').toLowerCase()) {
      case 'us':
        return 'US';
      case 'kr':
        return 'KR';
      case 'es':
        return 'SP';
      default:
        return 'US';
    }
  }

  String? _countryRuleText(String? country) {
    switch ((country ?? '').toLowerCase()) {
      case 'us':
        return t('usEduRule');
      case 'kr':
        return t('krDomainRule');
      case 'es':
        return t('esDomainRule');
      default:
        return null;
    }
  }

  /// Tutor: any birth year from 1900 through this calendar year.
  /// Student (ages 14–17): birth years derived from [DateTime.now] so they stay correct when the year rolls over.
  List<int> get _birthYearItems {
    final y = DateTime.now().year;
    if (widget.role == UserRole.becomeTutor) {
      return List.generate(y - 1900 + 1, (i) => y - i);
    }
    final youngestBirthYear = y - 14; // turns 14 this year
    final oldestBirthYear = y - 17; // turns 17 this year
    return List.generate(
      youngestBirthYear - oldestBirthYear + 1,
      (i) => youngestBirthYear - i,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countryRule = _countryRuleText(_country);
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
            _fieldHeader(t('selectCountry')),
            AppDropdownButton2<String>(
              hintText: t('country'),
              value: _country,
              items: const ['us', 'kr', 'es'],
              itemLabelBuilder: (v) {
                if (v == 'us') return t('unitedStates');
                if (v == 'kr') return t('southKorea');
                return t('spain');
              },
              onChanged: (v) => setState(() => _country = v),
            ),
            const SizedBox(height: ConstSize.grid * 1),
            if (countryRule != null) ...[
              Text(
                countryRule,
                style: const TextStyle(
                  color: ConstColor.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: ConstSize.grid * 2),
            _fieldHeader(t('enterEmail')),
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
            _fieldHeader(t('selectBirthYear')),
            AppDropdownButton2<int>(
              hintText: t('birthYear'),
              value: _selectedYear,
              items: _birthYearItems,
              itemLabelBuilder: (year) => '$year',
              onChanged: (year) => setState(() => _selectedYear = year),
            ),
            const SizedBox(height: ConstSize.grid * 1),
            Text(
              widget.role == UserRole.becomeTutor ? "" : t('ageRule'),
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
                } else if (state is SignupSuccess) {
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
                        country: _countryToApiCode(_country),
                        birthyear: _selectedYear?.toString() ?? '',
                        userrole:
                            widget.role.name.toLowerCase().toString() ==
                                'findtutor'
                            ? 'student'
                            : 'tutor',
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

  Widget _fieldHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ConstSize.grid),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
