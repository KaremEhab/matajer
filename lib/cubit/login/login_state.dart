part of 'login_cubit.dart';

abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoadingState extends LoginState {}

class LoginSuccessState extends LoginState {
  final String uId;

  LoginSuccessState(this.uId);
}

class LoginErrorState extends LoginState {
  final String error;

  LoginErrorState({required this.error});
}

class LoginForgetPasswordLoadingState extends LoginState {}

class LoginForgetPasswordSuccessState extends LoginState {}

class LoginForgetPasswordErrorState extends LoginState {
  final String error;

  LoginForgetPasswordErrorState({required this.error});
}

class DeleteGuestSuccessState extends LoginState {}

class DeleteGuestErrorState extends LoginState {
  final String error;

  DeleteGuestErrorState({required this.error});
}

class SignInWithGuestLoadingState extends LoginState {}

class SignInWithGuestSuccessState extends LoginState {}

class SignInWithGuestErrorState extends LoginState {
  final String error;

  SignInWithGuestErrorState({required this.error});
}

class SignInWithGoogleLoadingState extends LoginState {}

class SignInWithGoogleSuccessState extends LoginState {}

class SignInWithGoogleErrorState extends LoginState {
  final String error;

  SignInWithGoogleErrorState({required this.error});
}

class SignInWithFacebookLoadingState extends LoginState {}

class SignInWithFacebookSuccessState extends LoginState {}

class SignInWithFacebookErrorState extends LoginState {
  final String error;

  SignInWithFacebookErrorState({required this.error});
}

class SignInWithAppleLoadingState extends LoginState {}

class SignInWithAppleSuccessState extends LoginState {}

class SignInWithAppleErrorState extends LoginState {
  final String error;

  SignInWithAppleErrorState({required this.error});
}

class VerifyPhoneErrorState extends LoginState {
  final String error;

  VerifyPhoneErrorState({required this.error});
}
