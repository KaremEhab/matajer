abstract class UserState {}

class UserInitialState extends UserState {}

class GetShopByIdSuccessState extends UserState {}

class GetShopByIdErrorState extends UserState {}

class UserGetUserDataLoadingState extends UserState {}

class UserGetUserDataSuccessState extends UserState {}

class UserGetUserDataErrorState extends UserState {
  final String error;

  UserGetUserDataErrorState(this.error);
}

class UserUpdateFCMTokenLoadingState extends UserState {}

class UserUpdateFCMTokenSuccessState extends UserState {}

class UserUpdateFCMTokenErrorState extends UserState {
  final String error;

  UserUpdateFCMTokenErrorState(this.error);
}

class GetUserShopByIdLoadingState extends UserState {}

class GetUserShopByIdSuccessState extends UserState {}

class GetUserShopByIdErrorState extends UserState {
  final String error;

  GetUserShopByIdErrorState(this.error);
}

class UserUploadImageLoadingState extends UserState {}

class UserUploadImageSuccessState extends UserState {}

class UserUploadImageErrorState extends UserState {
  final String error;

  UserUploadImageErrorState(this.error);
}

class UserRegisterSellerLoadingState extends UserState {}

class UserRegisterSellerSuccessState extends UserState {}

class UserRegisterSellerErrorState extends UserState {
  final String error;

  UserRegisterSellerErrorState(this.error);
}

class UserChangeEmailLoadingState extends UserState {}

class UserChangeEmailSuccessState extends UserState {}

class UserChangeEmailErrorState extends UserState {
  final String error;

  UserChangeEmailErrorState(this.error);
}

class UserChangePasswordLoadingState extends UserState {}

class UserChangePasswordSuccessState extends UserState {}

class UserChangePasswordErrorState extends UserState {
  final String error;

  UserChangePasswordErrorState(this.error);
}

class UserUpdateBuyerDataLoadingState extends UserState {}

class UserUpdateBuyerDataSuccessState extends UserState {}

class UserUpdateBuyerDataErrorState extends UserState {
  final String error;

  UserUpdateBuyerDataErrorState(this.error);
}
