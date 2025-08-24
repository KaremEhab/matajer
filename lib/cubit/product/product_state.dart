import 'package:matajer/models/product_model.dart';

abstract class ProductState {}

class ProductInitialState extends ProductState {}

class ProductUploadImageLoadingState extends ProductState {}

class ProductUploadImageSuccessState extends ProductState {}

class ProductUploadImageErrorState extends ProductState {
  final String error;

  ProductUploadImageErrorState(this.error);
}

class ProductAddProductLoadingState extends ProductState {}

class ProductAddProductSuccessState extends ProductState {}

class ProductAddProductErrorState extends ProductState {
  final String error;

  ProductAddProductErrorState(this.error);
}

class ProductGetSellersLoadingState extends ProductState {}

class ProductGetSellersSuccessState extends ProductState {}

class ProductGetSellersErrorState extends ProductState {
  final String error;

  ProductGetSellersErrorState(this.error);
}

class ProductGetMoreSellersLoadingState extends ProductState {}

class ProductGetMoreSellersSuccessState extends ProductState {}

class ProductGetMoreSellersErrorState extends ProductState {
  final String error;
  ProductGetMoreSellersErrorState(this.error);
}

class ProductGetProductsLoadingState extends ProductState {}

class ProductGetProductsSuccessState extends ProductState {}

class ProductGetProductsErrorState extends ProductState {
  final String error;

  ProductGetProductsErrorState(this.error);
}

class ProductGetMoreProductsLoadingState extends ProductState {}

class ProductGetMoreProductsSuccessState extends ProductState {}

class ProductGetMoreProductsErrorState extends ProductState {
  final String error;

  ProductGetMoreProductsErrorState(this.error);
}

class ProductAddProductToFavoriteLoadingState extends ProductState {}

class ProductAddProductToFavoriteSuccessState extends ProductState {}

class ProductAddProductToFavoriteErrorState extends ProductState {
  final String error;

  ProductAddProductToFavoriteErrorState(this.error);
}

class ProductRemoveProductFromFavoriteLoadingState extends ProductState {}

class ProductRemoveProductFromFavoriteSuccessState extends ProductState {}

class ProductRemoveProductFromFavoriteErrorState extends ProductState {
  final String error;

  ProductRemoveProductFromFavoriteErrorState(this.error);
}

class ProductGetFavoriteProductsLoadingState extends ProductState {}

class ProductGetFavoriteProductsSuccessState extends ProductState {}

class ProductGetFavoriteProductsErrorState extends ProductState {
  final String error;

  ProductGetFavoriteProductsErrorState(this.error);
}

class ProductAddSellerToFavoriteLoadingState extends ProductState {}

class ProductAddSellerToFavoriteSuccessState extends ProductState {}

class ProductAddSellerToFavoriteErrorState extends ProductState {
  final String error;

  ProductAddSellerToFavoriteErrorState(this.error);
}

class ProductRemoveSellerFromFavoriteLoadingState extends ProductState {}

class ProductRemoveSellerFromFavoriteSuccessState extends ProductState {}

class ProductRemoveSellerFromFavoriteErrorState extends ProductState {
  final String error;

  ProductRemoveSellerFromFavoriteErrorState(this.error);
}

class ProductGetFavoriteShopsLoadingState extends ProductState {}

class ProductGetFavoriteShopsSuccessState extends ProductState {}

class ProductGetFavoriteShopsErrorState extends ProductState {
  final String error;

  ProductGetFavoriteShopsErrorState(this.error);
}

class ProductGetAllProductsLoadingState extends ProductState {}

class ProductGetAllProductsSuccessState extends ProductState {
  final List<ProductModel> products;

  ProductGetAllProductsSuccessState(this.products);
}

class ProductGetAllProductsErrorState extends ProductState {
  final String error;

  ProductGetAllProductsErrorState(this.error);
}

class ProductSearchProductsSuccessState extends ProductState {}

class ProductGetAllSellersLoadingState extends ProductState {}

class ProductGetAllSellersSuccessState extends ProductState {}

class ProductGetAllSellersErrorState extends ProductState {
  final String error;

  ProductGetAllSellersErrorState(this.error);
}

class ProductSearchSellersSuccessState extends ProductState {}

class ProductAddProductToCartLoadingState extends ProductState {}

class ProductAddProductToCartSuccessState extends ProductState {}

class ProductAddProductToCartErrorState extends ProductState {
  final String error;

  ProductAddProductToCartErrorState(this.error);
}

class ProductSearchLoadingState extends ProductState {}

class ProductSearchSuccessState extends ProductState {}

class ProductSearchErrorState extends ProductState {
  final String error;

  ProductSearchErrorState(this.error);
}

class ProductEditCartProductLoadingState extends ProductState {}

class ProductEditCartProductSuccessState extends ProductState {}

class ProductEditCartProductErrorState extends ProductState {
  final String error;
  ProductEditCartProductErrorState(this.error);
}

class ProductGetCartProductsLoadingState extends ProductState {}

class ProductGetCartProductsSuccessState extends ProductState {}

class ProductGetCartProductsErrorState extends ProductState {
  final String error;

  ProductGetCartProductsErrorState(this.error);
}

class ProductRemoveProductFromCartLoadingState extends ProductState {}

class ProductRemoveProductFromCartSuccessState extends ProductState {}

class ProductRemoveProductFromCartErrorState extends ProductState {
  final String error;

  ProductRemoveProductFromCartErrorState(this.error);
}

class ProductDecreaseProductQuantityInCartLoadingState extends ProductState {}

class ProductDecreaseProductQuantityInCartSuccessState extends ProductState {}

class ProductDecreaseProductQuantityInCartErrorState extends ProductState {
  final String error;

  ProductDecreaseProductQuantityInCartErrorState(this.error);
}

class ProductIncreaseProductQuantityInCartLoadingState extends ProductState {}

class ProductIncreaseProductQuantityInCartSuccessState extends ProductState {}

class ProductIncreaseProductQuantityInCartErrorState extends ProductState {
  final String error;

  ProductIncreaseProductQuantityInCartErrorState(this.error);
}

class ProductClearCartLoadingState extends ProductState {}

class ProductClearCartSuccessState extends ProductState {}

class ProductClearCartErrorState extends ProductState {
  final String error;

  ProductClearCartErrorState(this.error);
}

class ProductPlaceOrderSuccessState extends ProductState {}

class ProductPlaceOrderLoadingState extends ProductState {}

class ProductPlaceOrderErrorState extends ProductState {
  final String error;

  ProductPlaceOrderErrorState(this.error);
}

class ProductSaveAddressLoadingState extends ProductState {}

class ProductSaveAddressSuccessState extends ProductState {}

class ProductSaveAddressErrorState extends ProductState {
  final String error;

  ProductSaveAddressErrorState(this.error);
}

class ProductIncreaseProductClicksLoadingState extends ProductState {}

class ProductIncreaseProductClicksSuccessState extends ProductState {}

class ProductIncreaseProductClicksErrorState extends ProductState {
  final String error;

  ProductIncreaseProductClicksErrorState(this.error);
}

class ProductFilterProductsLoadingState extends ProductState {}

class ProductFilterProductsSuccessState extends ProductState {}

class FilteredProductsUpdatedState extends ProductState {}

class ProductFilterProductsErrorState extends ProductState {
  final String error;

  ProductFilterProductsErrorState(this.error);
}

class ProductPaypalPayLoadingState extends ProductState {}

class ProductPaypalPaySuccessState extends ProductState {
  final String paymentLink;

  ProductPaypalPaySuccessState(this.paymentLink);
}

class ProductPaypalPayErrorState extends ProductState {
  final String error;

  ProductPaypalPayErrorState(this.error);
}

class ProductGetSellerLoadingState extends ProductState {}

class ProductGetSellerSuccessState extends ProductState {}

class ProductGetSellerErrorState extends ProductState {
  final String error;

  ProductGetSellerErrorState(this.error);
}

class ProductGetProductsByCategoryLoadingState extends ProductState {}

class ProductGetProductsByCategorySuccessState extends ProductState {}

class ProductGetProductsByCategoryErrorState extends ProductState {
  final String error;

  ProductGetProductsByCategoryErrorState(this.error);
}

class ProductSearchSellerProductsSuccessState extends ProductState {}

class ProductGetAppCommissionLoadingState extends ProductState {}

class ProductGetAppCommissionSuccessState extends ProductState {
  final num commission;

  ProductGetAppCommissionSuccessState(this.commission);
}

class ProductGetAppCommissionErrorState extends ProductState {
  final String error;

  ProductGetAppCommissionErrorState(this.error);
}
