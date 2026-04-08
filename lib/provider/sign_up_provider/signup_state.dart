part of 'signup_bloc.dart';

sealed class SignupState extends Equatable {
  const SignupState();
  
  @override
  List<Object?> get props => [];
}

final class SignupInitial extends SignupState {}
final class SignupLoading extends SignupState {}

final class SignupSuccess extends SignupState {
  final SignupModel signupprovider;

  const SignupSuccess(this.signupprovider);

  @override
  List<Object?> get props => [signupprovider];
}


final class SignupError extends SignupState {
  final String message;

  const SignupError(this.message);

  @override
  List<Object?> get props => [message];
}
