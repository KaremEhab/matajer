abstract class WalletState {}

class WalletInitialState extends WalletState {}

class WalletGetWalletDataLoadingState extends WalletState {}
class WalletGetWalletDataSuccessState extends WalletState {}
class WalletGetWalletDataErrorState extends WalletState {
  final String error;

  WalletGetWalletDataErrorState(this.error);
}

class WalletAddWithdrawRequestLoadingState extends WalletState {}
class WalletAddWithdrawRequestSuccessState extends WalletState {}
class WalletAddWithdrawRequestErrorState extends WalletState {
  final String error;

  WalletAddWithdrawRequestErrorState(this.error);
}
