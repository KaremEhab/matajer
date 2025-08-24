import 'package:matajer/models/product_model.dart';

class CartProductItemModel {
  late String id;
  late ProductModel product;
  late int quantity;
  List<Map<String, String>> selectedSpecifications = [];
  late num piecePrice;
  late num totalPrice;
  bool isOffer = false;

  CartProductItemModel({
    required this.product,
    required this.quantity,
    this.selectedSpecifications = const [],
    this.isOffer = false,
  }) {
    _calculatePrices();
  }

  CartProductItemModel.fromJson(Map<String, dynamic> json, this.id) {
    product = ProductModel.fromJson(json['product']);
    quantity = json['quantity'] ?? 1;

    selectedSpecifications = [];
    if (json['selectedSpecifications'] != null) {
      for (var spec in json['selectedSpecifications']) {
        selectedSpecifications.add({
          'title': spec['title']?.toString() ?? '',
          'value': spec['value']?.toString() ?? '',
        });
      }
    }

    isOffer = json['isOffer'] ?? false;

    _calculatePrices();
  }

  void _calculatePrices() {
    num extraSpecsPrice = 0;

    for (var selected in selectedSpecifications) {
      final title = selected['title'];
      final value = selected['value'];

      final spec = product.specifications.firstWhere(
        (s) => s.title == title,
        orElse: () => ProductSpecificationModel(title: '', subTitles: []),
      );

      final specValue = spec.subTitles.firstWhere(
        (v) => v.title == value,
        orElse: () => ProductSpecificationValueModel(title: '', price: 0),
      );

      extraSpecsPrice += specValue.price;
    }

    // Base price including extra specs
    piecePrice = product.price + extraSpecsPrice;

    // Apply discount unconditionally if product.discount exists
    if (product.discount > 0) {
      piecePrice = piecePrice * (1 - product.discount / 100);
    }

    // Total price for the quantity
    totalPrice = piecePrice * quantity;
  }

  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'quantity': quantity,
      'selectedSpecifications': selectedSpecifications,
      'isOffer': isOffer,
      'piecePrice': piecePrice,
      'totalPrice': totalPrice,
    };
  }
}
