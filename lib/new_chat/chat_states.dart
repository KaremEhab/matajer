abstract class ChatStates {}

class ChatInitialState extends ChatStates {}

class ChatRegisterLoadingState extends ChatStates {}

class ChatRegisterSuccessState extends ChatStates {}

class ChatRegisterErrorState extends ChatStates {
  final String error;
  ChatRegisterErrorState(this.error);
}

class ChatGetUsersLoadingState extends ChatStates {}

class ChatGetUsersSuccessState extends ChatStates {}

class ChatGetUsersErrorState extends ChatStates {
  final String error;
  ChatGetUsersErrorState(this.error);
}

class ChatSendMessageLoadingState extends ChatStates {}

class ChatSearchSuccessState extends ChatStates {}

class ChatSendMessageSuccessState extends ChatStates {}

class ChatSendMessageErrorState extends ChatStates {
  final String error;
  ChatSendMessageErrorState(this.error);
}

class SelectImageErrorState extends ChatStates {
  final String error;
  SelectImageErrorState(this.error);
}

class UploadImageLoadingState extends ChatStates {}

class UploadImageSuccessState extends ChatStates {}

class UploadImageErrorState extends ChatStates {
  final String error;
  UploadImageErrorState(this.error);
}

class SendNotificationLoadingState extends ChatStates {}

class SendNotificationSuccessState extends ChatStates {}

class SendNotificationErrorState extends ChatStates {
  final String error;
  SendNotificationErrorState(this.error);
}

class ChatGetReciverDataSuccessState extends ChatStates {}

class ChatGetReciverDataLoadingState extends ChatStates {}

class ChatGetReciverDataErrorState extends ChatStates {
  final String error;
  ChatGetReciverDataErrorState(this.error);
}

class ChatGetFcmTokensLoadingState extends ChatStates {}

class ChatGetFcmTokensSuccessState extends ChatStates {}

class ChatPinLoadingState extends ChatStates {}

class ChatPinSuccessState extends ChatStates {}

class ChatPinErrorState extends ChatStates {
  final String error;
  ChatPinErrorState(this.error);
}

class ChatDeleteLoadingState extends ChatStates {}
class ChatDeleteSuccessState extends ChatStates {}
class ChatDeleteErrorState extends ChatStates {
  final String error;
  ChatDeleteErrorState(this.error);
}
