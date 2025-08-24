class FavouritesModel {
  List<String> favShops = [];
  List<String> favProducts = [];

  FavouritesModel({required this.favShops, required this.favProducts});

  FavouritesModel.fromJson(Map<String, dynamic> json) {
    favShops =
        (json['favShops'] as List?)?.map((e) => e.toString()).toList() ?? [];
    favProducts =
        (json['favProducts'] as List?)?.map((e) => e.toString()).toList() ?? [];
  }

  Map<String, dynamic> toJson() {
    return {'favShops': favShops, 'favProducts': favProducts};
  }
}
