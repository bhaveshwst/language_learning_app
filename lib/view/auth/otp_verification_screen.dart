import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/auth_flow.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/user_role.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/provider/login_provider/login_provider_bloc.dart';
import 'package:language_learning_app/provider/sign_up_provider/signup_bloc.dart';
import 'package:language_learning_app/provider/verify_otp/verify_otp_bloc.dart';
import 'package:language_learning_app/view/auth/complete_profile_screen.dart';
import 'package:language_learning_app/view/auth/widgets/auth_primary_button.dart';
import 'package:language_learning_app/view/auth/widgets/auth_screen_shell.dart';
import 'package:pinput/pinput.dart';
import 'package:language_learning_app/core/auth/pending_booking_intent.dart';
import 'package:language_learning_app/view/student/screens/student_resume_booking_host.dart';
import 'package:language_learning_app/view/student/student_dashboard_shell.dart';
import 'package:language_learning_app/view/tutor/tutor_dashboard_shell.dart';

/// Same payload as the initial signup request; needed to resend OTP via [ConstApiUrl.signupURL].
class SignupOtpResendInfo {
  const SignupOtpResendInfo({
    required this.country,
    required this.birthYear,
    required this.userRole,
  });

  final String country;
  final String birthYear;
  final String userRole;
}

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.language,
    required this.role,
    required this.authFlow,
    required this.email,
    this.signupResend,
  }) : assert(
         authFlow != AuthFlow.signup || signupResend != null,
         'signupResend is required when authFlow is signup',
       );

  final AppLanguage language;
  final UserRole role;
  final AuthFlow authFlow;
  final String email;
  final SignupOtpResendInfo? signupResend;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String t(String key) => ConstString.text(widget.language, key);
  final TextEditingController _otpController = TextEditingController();
  final VerifyOtpBloc _verifyOtpBloc = VerifyOtpBloc();
  LoginProviderBloc? _loginResendBloc;
  SignupBloc? _signupResendBloc;
  static const int _resendCooldownSeconds = 30;
  int _secondsRemaining = _resendCooldownSeconds;
  Timer? _timer;

  bool get _isResendEnabled => _secondsRemaining == 0;

  @override
  void initState() {
    super.initState();
    if (widget.authFlow == AuthFlow.login) {
      _loginResendBloc = LoginProviderBloc();
    } else {
      _signupResendBloc = SignupBloc();
    }
    _startResendTimer();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = _resendCooldownSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  String get _formattedTime => _secondsRemaining.toString().padLeft(2, '0');

  void _onResendCodePressed() {
    _startResendTimer();
    _otpController.clear();

    if (widget.authFlow == AuthFlow.login) {
      _loginResendBloc?.add(LoginProvider(email: widget.email));
      return;
    }

    final info = widget.signupResend;
    if (info == null) return;
    _signupResendBloc?.add(
      SignupProvider(
        email: widget.email,
        country: info.country,
        birthyear: info.birthYear,
        userrole: info.userRole,
      ),
    );
  }

  void _onVerifyOtpListen(BuildContext context, VerifyOtpState state) async {
    if (state is VerifyOtpInitial) {
    } else if (state is VerifyOtpLoading) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return Center(child: const CircularProgressIndicator());
        },
      );
    } else if (state is VerifyOtpError) {
      Navigator.pop(context);
      commonAlertDialog(context, state.message);
    } else if (state is VerifyOtpSuccess) {
      Navigator.pop(context);
      await PrefUtils.setToken(
        state.verifyotpprovider.data?.accessToken ?? "",
      );
      await PrefUtils.settutorid(
        state.verifyotpprovider.data?.tutorid ?? "",
      );
      await PrefUtils.setstudentid(
        state.verifyotpprovider.data?.studentid ?? "",
      );
      await PrefUtils.setUserType(
        widget.role == UserRole.becomeTutor ? 'tutor' : 'student',
      );
      if (!context.mounted) return;
      if (widget.authFlow == AuthFlow.signup) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(
              language: widget.language,
              role: widget.role,
            ),
          ),
        );
        return;
      }

      final Widget targetDashboard = widget.role == UserRole.becomeTutor
          ? const TutorDashboardShell()
          : (PendingBookingIntent.hasPending
                ? const StudentResumeBookingHost()
                : const StudentDashboardShell());
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => targetDashboard),
        (route) => false,
      );
    }
  }

  void _onResendLoginListen(BuildContext context, LoginProviderState state) {
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
      commonAlertDialog(context, t('otpResentSuccess'));
    }
  }

  void _onResendSignupListen(BuildContext context, SignupState state) {
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
      commonAlertDialog(context, t('otpResentSuccess'));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _verifyOtpBloc.close();
    _loginResendBloc?.close();
    _signupResendBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<VerifyOtpBloc>.value(value: _verifyOtpBloc),
        if (_loginResendBloc != null)
          BlocProvider<LoginProviderBloc>.value(value: _loginResendBloc!),
        if (_signupResendBloc != null)
          BlocProvider<SignupBloc>.value(value: _signupResendBloc!),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<VerifyOtpBloc, VerifyOtpState>(
            listener: _onVerifyOtpListen,
          ),
          if (widget.authFlow == AuthFlow.login && _loginResendBloc != null)
            BlocListener<LoginProviderBloc, LoginProviderState>(
              bloc: _loginResendBloc,
              listener: _onResendLoginListen,
            )
          else if (_signupResendBloc != null)
            BlocListener<SignupBloc, SignupState>(
              bloc: _signupResendBloc,
              listener: _onResendSignupListen,
            ),
        ],
        child: AuthScreenShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  border: Border.all(
                    color: ConstColor.primaryBlue.withOpacity(0.1),
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.email, color: ConstColor.primaryBlue, size: 26),
              ),
              SizedBox(height: 20),
              Text(
                t('otpTitle'),
                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: ConstSize.grid),
              Text(
                t('otpSubtitle'),
                style: const TextStyle(color: ConstColor.textSecondary),
              ),
              const SizedBox(height: ConstSize.grid),
              Text(
                '${t('otpSentTo')}: ${widget.email}',
                style: const TextStyle(
                  color: ConstColor.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: ConstSize.grid * 4),
              Pinput(
                controller: _otpController,
                keyboardType: TextInputType.phone,
                length: 6,
                defaultPinTheme: PinTheme(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(ConstSize.radiusM),
                    border: Border.all(color: ConstColor.primaryBlue),
                  ),
                ),
              ),
              const SizedBox(height: ConstSize.grid * 3),
              Center(
                child: Text(
                  '🕓 00:$_formattedTime',
                  style: const TextStyle(
                    color: ConstColor.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: _isResendEnabled ? _onResendCodePressed : null,
                  child: Text(
                    t('resendCode'),
                    style: TextStyle(
                      color: _isResendEnabled
                          ? ConstColor.primaryBlue
                          : ConstColor.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: ConstSize.grid * 2),
              AuthPrimaryButton(
                text: t('verify'),
                onPressed: () {
                  if (_otpController.text.trim().isEmpty) {
                    commonAlertDialog(context, t('enterOtpError'));
                  } else {
                    _verifyOtpBloc.add(
                      VerifyOtpProvider(otp: _otpController.text.trim()),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
