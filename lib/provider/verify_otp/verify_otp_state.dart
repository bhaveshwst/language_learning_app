part of 'verify_otp_bloc.dart';

sealed class VerifyOtpState extends Equatable {
  const VerifyOtpState();
  
  @override
  List<Object?> get props => [];
}

final class VerifyOtpInitial extends VerifyOtpState {}
final class VerifyOtpLoading extends VerifyOtpState {}
final class VerifyOtpSuccess extends VerifyOtpState {
   final VerifyOtpModel verifyotpprovider;

  const VerifyOtpSuccess(this.verifyotpprovider);

  @override
  List<Object?> get props => [verifyotpprovider];
}
final class VerifyOtpError extends VerifyOtpState {
    final String message;

  const VerifyOtpError(this.message);

  @override
  List<Object?> get props => [message];
}

