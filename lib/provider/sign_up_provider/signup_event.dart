part of 'signup_bloc.dart';

sealed class SignupEvent extends Equatable {
  const SignupEvent();

  @override
  List<Object?> get props => [];
}

class SignupProvider extends SignupEvent {
  final String email;
  final String country;
  final String birthyear;
  final String userrole;

  const SignupProvider({
    required this.email,
    required this.country,
    required this.birthyear,
    required this.userrole,
  });

  @override
  List<Object?> get props => [email, country, birthyear, userrole];
}