abstract class NotificationState {}

class NotificationInitialState extends NotificationState {}

class NotificationGetNotificationsLoadingState extends NotificationState {}

class NotificationGetNotificationsSuccessState extends NotificationState {}

class NotificationGetNotificationsErrorState extends NotificationState {
  final String error;
  NotificationGetNotificationsErrorState(this.error);
}

class SendNotificationLoadingState extends NotificationState {}

class SendNotificationSuccessState extends NotificationState {}

class SendNotificationErrorState extends NotificationState {
  final String error;
  SendNotificationErrorState(this.error);
}
