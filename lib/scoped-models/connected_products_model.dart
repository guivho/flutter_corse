import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_mode.dart';
import '../models/fb_auth_data.dart';
import '../models/form_data.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../utils/constants.dart';

mixin ConnectedProductsModel on Model {
  final Map<String, Product> _products = {};
  User _authenticatedUser;
  bool _isLoading = false;
  String token;

  bool get isLoading {
    return _isLoading;
  }
}

mixin ProductsModel on ConnectedProductsModel {
  bool _showFavoritesOnly = false;
  bool get showFavoriteOnly {
    return _showFavoritesOnly;
  }

  List<Product> get allProducts {
    return List.from(_products.values);
  }

  List<Product> get displayedProducts {
    final List<Product> products = _showFavoritesOnly
        ? List.from(_products.values.where((p) => p.isFavorite == true))
        : List.from(_products.values);
    print('displayedProducts: $products');
    return products;
  }

  Future<bool> addProduct(FormData formData) {
    _isLoading = true;
    notifyListeners();
    final Map<String, dynamic> productData = formData.toProductData(
        _authenticatedUser.email, _authenticatedUser.userId);
    print('productData: $productData');
    return http
        .post('$PRODUCTSURL?auth=${_authenticatedUser.token}',
            body: json.encode(productData))
        .then((http.Response response) {
      final bool ok = response.statusCode == 200 || response.statusCode == 201;
      if (ok) {
        print('response.body: ${response.body}');
        final Map<String, dynamic> jsonData = json.decode(response.body);
        print('jsonData: $jsonData');
        final Product newProduct =
            Product.fromJson(jsonData[NAME], productData);
        print('newProduct: $newProduct');
        _products[newProduct.productId] = newProduct;
        print('_products: $_products');
      } else {
        print('(addProduct) statusCode: ${response.statusCode}');
      }
      _isLoading = false;
      notifyListeners();
      return ok;
    }).catchError((error) {
      print('(addProduct) catchError: $error');
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }

  void _removeAllProducts() {
    // delete local copies before fetchng from server
    _products.removeWhere((String key, Product product) {
      return key != null;
    });
  }

  // Future only returned to be able to use RefreshIndicator
  // (Note this onw using aync and await rather than .then
  // both are equivalent)
  Future<bool> fetchProducts() async {
    _isLoading = true;
    notifyListeners();
    print('[model] fetchProducts');
    try {
      final String url = '$PRODUCTSURL?auth=${_authenticatedUser.token}';
      final http.Response response = await http.get(url);
      print('statuscode: ${response.statusCode} from url: $url');
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('(fetchProducts) statusCode: ${response.statusCode}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
      Map<String, dynamic> productListData = json.decode(response.body);
      _removeAllProducts();
      if (productListData != null) {
        productListData.forEach((String productId, dynamic productData) {
          _products[productId] = Product.fromJson(productId, productData);
        });
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      print('(fetchProducts) catch error: $error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Product productWithId(String productId) {
    if (_products.containsKey(productId)) {
      return _products[productId];
    }
    return null;
  }

  Future<bool> toggleFavorite(String productId) {
    return _updateProduct(Product.favoriteToggled(_products[productId]));
  }

  Future<bool> updateProduct(String productId, FormData formData) {
    final Product product = Product.fromForm(productId, formData);
    return _updateProduct(product);
  }

  Future<bool> _updateProduct(Product product) {
    _isLoading = true;
    notifyListeners();
    final Map<String, dynamic> productData = product.toProductData();
    return http
        .put(
            '$DBSERVER$PRODUCTS/${product.productId}$JSON?auth=${_authenticatedUser.token}',
            body: json.encode(productData))
        .then((http.Response response) {
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('(updateProduct) statusCode: ${response.statusCode}');
        return false;
      }
      _products[product.productId] = product;
      _isLoading = false;
      notifyListeners();
      return true;
    }).catchError((error) {
      print('(_updateProduct) catchError: $error');
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }

  Future<bool> deleteProduct(String productId) {
    _isLoading = true;
    notifyListeners();
    return http
        .delete(
            '$DBSERVER$PRODUCTS/$productId$JSON?auth=${_authenticatedUser.token}')
        .then((http.Response response) {
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('(deleteProduct) statusCode: ${response.statusCode}');
        return false;
      }
      _products.remove(productId);
      _isLoading = false;
      notifyListeners();
      return true;
    }).catchError((error) {
      print('(deleteProduct) catchError: $error');
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }

  void toggleShowFavorites() {
    _showFavoritesOnly = !_showFavoritesOnly;
    notifyListeners();
  }
}

mixin UsersModel on ConnectedProductsModel {
  Future<Map<String, dynamic>> authenticate(
      AuthMode authMode, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    final Map<String, dynamic> authData =
        FbAuthData(email, password).toMapStringDynamic();
    final String url =
        '${authMode == AuthMode.Login ? FB_LOGIN : FB_SIGNUP}$FB_APIKEY';
    final http.Response response =
        await http.post(url, body: json.encode(authData));
    bool isOk = true;
    String message = 'Authentication succeeded!';
    final Map<String, dynamic> responseData = json.decode(response.body);
    print("responseData: $responseData");
    if (response.statusCode == 200 && responseData.containsKey(FB_IDTOKEN)) {
      final dynamic userData = json.decode(response.body);
      _authenticatedUser = User.fromJson(userData);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(FB_IDTOKEN, userData[FB_IDTOKEN]);
      prefs.setString(FB_EMAIL, userData[FB_EMAIL]);
      prefs.setString(FB_LOCALID, userData[FB_LOCALID]);
      print('_authenticated_user: $_authenticatedUser');
    } else {
      isOk = false;
      if (responseData['error']['message'] == 'EMAIL_NOT_FOUND') {
        message = 'Email not found!';
      } else if (responseData['error']['message'] == 'INVALID_PASSWORD') {
        message = 'Invalid password!';
      } else if (responseData['error']['message'] == 'EMAIL_EXISTS') {
        message = 'Email already exists!';
      } else {
        message = 'Something went wrong!';
      }
    }
    _isLoading = false;
    notifyListeners();
    return {FB_SUCCESS: isOk, 'message': message};
  }

  Future<bool> autoAuthenticate() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    final token = _prefs.getString(FB_IDTOKEN);
    bool ok = false;
    _authenticatedUser = null;
    if (token != null) {
      final email = _prefs.getString(FB_EMAIL);
      final userId = _prefs.getString(FB_LOCALID);
      _authenticatedUser = User(email: email, token: token, userId: userId);
      ok = true;
    }
    notifyListeners();
    return ok;
  }

  User get user {
    return _authenticatedUser;
  }

  void logout() async {
    _authenticatedUser = null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(FB_IDTOKEN);
    prefs.remove(FB_EMAIL);
    prefs.remove(FB_LOCALID);
    notifyListeners();
  }
}
