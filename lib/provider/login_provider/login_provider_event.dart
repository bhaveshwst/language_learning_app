part of 'login_provider_bloc.dart';

sealed class LoginProviderEvent extends Equatable {
  const LoginProviderEvent();

  @override
  List<Object?> get props => [];
}

class LoginProvider extends LoginProviderEvent {
  final String email;

  const LoginProvider({required this.email});

  @override
  List<Object?> get props => [email];
}
