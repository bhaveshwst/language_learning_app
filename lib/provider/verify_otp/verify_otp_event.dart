part of 'verify_otp_bloc.dart';

sealed class VerifyOtpEvent extends Equatable {
  const VerifyOtpEvent();

  @override
  List<Object?> get props => [];
}

class VerifyOtpProvider extends VerifyOtpEvent {
  final String otp;

  const VerifyOtpProvider({
    required this.otp,
  });

  @override
  List<Object?> get props => [otp];
}
