abstract class ChatsStates {}

class ChatsInitialState extends ChatsStates {}

class ChatImageMessageLoadingState extends ChatsStates {
  final String messageId;
  ChatImageMessageLoadingState(this.messageId);
}

class ChatImageMessageSuccessState extends ChatsStates {}

class ChatImageMessageErrorState extends ChatsStates {
  final String error;
  ChatImageMessageErrorState(this.error);
}

class ChatSelectionUpdated extends ChatsStates {}

class ChatSelectionCleared extends ChatsStates {}

class ChatDeleteLoadingState extends ChatsStates {}

class ChatDeleteSuccessState extends ChatsStates {}

class ChatDeleteErrorState extends ChatsStates {
  final String error;
  ChatDeleteErrorState(this.error);
}

class OfferMessageLoadingState extends ChatsStates {}

class OfferMessageSentSuccessfullyState extends ChatsStates {}

class OfferMessageErrorState extends ChatsStates {
  final String error;
  OfferMessageErrorState(this.error);
}

class ChatDeletedForMeLoadingState extends ChatsStates {}

class ChatDeletedForMeSuccessState extends ChatsStates {}

class ChatDeletedForMeErrorState extends ChatsStates {
  final String error;
  ChatDeletedForMeErrorState(this.error);
}

class SendNotificationLoadingState extends ChatsStates {}

class SendNotificationSuccessState extends ChatsStates {}

class SendNotificationErrorState extends ChatsStates {
  final String error;
  SendNotificationErrorState(this.error);
}
