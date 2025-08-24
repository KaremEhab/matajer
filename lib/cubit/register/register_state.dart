part of 'register_cubit.dart';

abstract class RegisterState {}

class RegisterInitialState extends RegisterState {}

class RegisterLoadingState extends RegisterState {}

class RegisterSuccessState extends RegisterState {
  final String uId;

  RegisterSuccessState(this.uId);
}

class RegisterErrorState extends RegisterState {
  final String error;

  RegisterErrorState({required this.error});
}

class RegisterCreateUserLoadingState extends RegisterState {}

class RegisterCreateUserSuccessState extends RegisterState {}

class RegisterCreateUserErrorState extends RegisterState {
  final String error;

  RegisterCreateUserErrorState(this.error);
}

class RegisterPhoneLoadingState extends RegisterState {}

class RegisterPhoneSuccessState extends RegisterState {}

class RegisterPhoneErrorState extends RegisterState {
  final String error;

  RegisterPhoneErrorState(this.error);
}

class RegisterSendOtpSuccessState extends RegisterState {
  final String verificationId;

  RegisterSendOtpSuccessState(this.verificationId);
}

class RegisterVerifyPhoneLoadingState extends RegisterState {}

class RegisterVerifyPhoneSuccessState extends RegisterState {}

class RegisterVerifyPhoneErrorState extends RegisterState {
  final String error;

  RegisterVerifyPhoneErrorState(this.error);
}

class SignUpWithGoogleLoadingState extends RegisterState {}

class SignUpWithGoogleSuccessState extends RegisterState {}

class SignUpWithGoogleErrorState extends RegisterState {
  final String error;

  SignUpWithGoogleErrorState({required this.error});
}

class SignUpWithFacebookLoadingState extends RegisterState {}

class SignUpWithFacebookSuccessState extends RegisterState {}

class SignUpWithFacebookErrorState extends RegisterState {
  final String error;

  SignUpWithFacebookErrorState({required this.error});
}

class SignUpWithAppleLoadingState extends RegisterState {}

class SignUpWithAppleSuccessState extends RegisterState {}

class SignUpWithAppleErrorState extends RegisterState {
  final String error;

  SignUpWithAppleErrorState({required this.error});
}
