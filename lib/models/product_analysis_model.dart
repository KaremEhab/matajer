class ProductAnalysisModel{
  final String name;
  final String sellerName;
  final String image;
  final String id;
  num orders;
  num sales;
  num clicks;

  ProductAnalysisModel({
    required this.name,
    required this.image,
    required this.sellerName,
    required this.id,
    required this.orders,
    required this.sales,
    required this.clicks,
  });
}