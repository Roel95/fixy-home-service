import 'package:flutter/foundation.dart';
import 'package:fixy_home_service/models/product_model.dart';

class FavoritesProvider extends ChangeNotifier {
  final Set<String> _favoriteIds = {};

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  void toggleFavorite(String productId) {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    notifyListeners();
  }

  void addFavorite(String productId) {
    if (!_favoriteIds.contains(productId)) {
      _favoriteIds.add(productId);
      notifyListeners();
    }
  }

  void removeFavorite(String productId) {
    if (_favoriteIds.remove(productId)) {
      notifyListeners();
    }
  }

  List<ProductModel> getFavoriteProducts(List<ProductModel> allProducts) {
    return allProducts.where((p) => _favoriteIds.contains(p.id)).toList();
  }

  int get favoritesCount => _favoriteIds.length;
}
