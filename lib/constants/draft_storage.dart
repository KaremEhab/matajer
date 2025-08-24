import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matajer/models/product_model.dart';

class DraftsStorage {
  static String _draftsKey(String shopId) => 'product_drafts_shop_$shopId';

  /// Save a draft product for a specific shop
  static Future<void> saveDraft(ProductModel product) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _draftsKey(product.shopId);
    final drafts = prefs.getStringList(key) ?? [];

    final List<Map<String, dynamic>> decodedDrafts =
        drafts.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    final productMap = product.toMap();
    final existingIndex = decodedDrafts.indexWhere(
      (d) => d['id'] == product.id,
    );

    if (existingIndex != -1) {
      decodedDrafts[existingIndex] = productMap;
    } else {
      decodedDrafts.add(productMap);
    }

    final updatedDrafts = decodedDrafts.map(jsonEncode).toList();
    await prefs.setStringList(key, updatedDrafts);
  }

  /// Get all drafts for a specific shop
  static Future<List<ProductModel>> getDrafts(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    final draftsJson = prefs.getStringList(_draftsKey(shopId)) ?? [];

    return draftsJson
        .map((jsonStr) => ProductModel.fromJson(jsonDecode(jsonStr)))
        .toList();
  }

  /// Remove a specific draft from a shop
  static Future<void> removeDraft(String shopId, String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _draftsKey(shopId);
    final draftsJson = prefs.getStringList(key) ?? [];

    final filteredDrafts =
        draftsJson.where((jsonStr) {
          final map = jsonDecode(jsonStr);
          return map['id'] != productId;
        }).toList();

    await prefs.setStringList(key, filteredDrafts);
  }

  /// Clear all drafts for a shop
  static Future<void> clearDrafts(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftsKey(shopId));
  }
}
