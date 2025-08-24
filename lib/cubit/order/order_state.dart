import 'package:matajer/models/order_model.dart';

abstract class OrderState {}

class OrderInitial extends OrderState {}

class OrderGetSellerOrdersLoadingState extends OrderState {}

class OrderGetSellerOrdersSuccessState extends OrderState {}

class OrderGetSellerOrdersErrorState extends OrderState {
  final String error;

  OrderGetSellerOrdersErrorState(this.error);
}

class OrderOrderScreenInitLoadingState extends OrderState {}

class OrderOrderScreenInitSuccessState extends OrderState {}

class OrderChangeOrderStatusLoadingState extends OrderState {}

class OrderChangeOrderStatusSuccessState extends OrderState {}

class OrderChangeOrderStatusErrorState extends OrderState {
  final String error;

  OrderChangeOrderStatusErrorState(this.error);
}

class OrderGetBuyerOrdersLoadingState extends OrderState {}

class OrderGetBuyerOrdersSuccessState extends OrderState {}

class OrderGetBuyerOrdersErrorState extends OrderState {
  final String error;

  OrderGetBuyerOrdersErrorState(this.error);
}

class OrderGetByIdLoadingState extends OrderState {}

class OrderGetByIdSuccessState extends OrderState {
  final OrderModel order;
  OrderGetByIdSuccessState(this.order);
}

class OrderGetByIdErrorState extends OrderState {
  final String error;

  OrderGetByIdErrorState(this.error);
}

class OrderPaypalPayLoadingState extends OrderState {}

class OrderPaypalPaySuccessState extends OrderState {
  final String paymentLink;

  OrderPaypalPaySuccessState(this.paymentLink);
}

class OrderPaypalPayErrorState extends OrderState {
  final String error;

  OrderPaypalPayErrorState(this.error);
}

class OrderRefundOrderLoadingState extends OrderState {}

class OrderRefundOrderSuccessState extends OrderState {}

class OrderRefundOrderErrorState extends OrderState {
  final String error;

  OrderRefundOrderErrorState(this.error);
}

class OrderSubmitRatingLoadingState extends OrderState {}

class OrderSubmitRatingSuccessState extends OrderState {}

class OrderSubmitRatingErrorState extends OrderState {
  final String error;

  OrderSubmitRatingErrorState(this.error);
}
