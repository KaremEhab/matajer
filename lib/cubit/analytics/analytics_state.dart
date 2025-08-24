abstract class AnalyticsState {}

final class AnalyticsInitialState extends AnalyticsState {}
class AnalyticsGetMonthlySalesLoadingState extends AnalyticsState {}
class AnalyticsGetMonthlySalesSuccessState extends AnalyticsState {}
class AnalyticsGetMonthlySalesErrorState extends AnalyticsState {
  final String error;
  AnalyticsGetMonthlySalesErrorState(this.error);
}

class AnalyticsGetAnnuallySalesLoadingState extends AnalyticsState {}
class AnalyticsGetAnnuallySalesSuccessState extends AnalyticsState {}
class AnalyticsGetAnnuallySalesErrorState extends AnalyticsState {
  final String error;
  AnalyticsGetAnnuallySalesErrorState(this.error);
}

class AnalyticsGetWeeklySalesLoadingState extends AnalyticsState {}
class AnalyticsGetWeeklySalesSuccessState extends AnalyticsState {}
class AnalyticsGetWeeklySalesErrorState extends AnalyticsState {
  final String error;
  AnalyticsGetWeeklySalesErrorState(this.error);
}

class AnalyticsGetDailySalesLoadingState extends AnalyticsState {}
class AnalyticsGetDailySalesSuccessState extends AnalyticsState {}
class AnalyticsGetDailySalesErrorState extends AnalyticsState {
  final String error;
  AnalyticsGetDailySalesErrorState(this.error);
}

// class AnalyticsGetProductsLoadingState extends AnalyticsState {}
// class AnalyticsGetProductsSuccessState extends AnalyticsState {}
// class AnalyticsGetProductsErrorState extends AnalyticsState {
//   final String error;
//   AnalyticsGetProductsErrorState(this.error);
// }
//
// class AnalyticsGetOrdersLoadingState extends AnalyticsState {}
// class AnalyticsGetOrdersSuccessState extends AnalyticsState {}
// class AnalyticsGetOrdersErrorState extends AnalyticsState {
//   final String error;
//   AnalyticsGetOrdersErrorState(this.error);
// }