part of 'login_provider_bloc.dart';

sealed class LoginProviderState extends Equatable {
  const LoginProviderState();
  
  @override
  List<Object?> get props => [];
}

final class LoginProviderInitial extends LoginProviderState {}
final class LoginProviderLoading extends LoginProviderState {}

final class LoginProviderSuccess extends LoginProviderState {
  final LoginModel loginmodelprovider;

  const LoginProviderSuccess(this.loginmodelprovider);

  @override
  List<Object?> get props => [loginmodelprovider];
}


final class LoginProviderError extends LoginProviderState {
  final String message;

  const LoginProviderError(this.message);

  @override
  List<Object?> get props => [message];
}

