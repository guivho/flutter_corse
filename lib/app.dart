import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
import 'package:scoped_model/scoped_model.dart';

import './pages/products_admin_page.dart';
import './pages/products_page.dart';
import './pages/product_page.dart';
import './pages/auth_page.dart';
import './scoped-models/main_model.dart';
import './utils/constants.dart';

class App extends StatefulWidget {
  @override
  _AppState createState() => new _AppState();
}

class _AppState extends State<App> {
  final MainModel _model = MainModel();

  @override
  void initState() {
    _model.autoAuthenticate();
    super.initState();
  }

  @override
  //final String _product = 'Food tester';
  Widget build(BuildContext context) {
    print('[app] build');
    return ScopedModel<MainModel>(
      model: _model,
      child: _buildMaterialApp(_model),
    );
  }

  MaterialApp _buildMaterialApp(MainModel model) {
    return MaterialApp(
      // debugShowMaterialGrid: true,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepOrange,
        accentColor: Colors.red,
        buttonColor: Colors.deepOrange,

        // fontFamily: 'Oswald',
      ),
      // home: AuthPage(),
      routes: defineRoutes(context, model),
      onGenerateRoute: (RouteSettings settings) {
        return defineOnGenerateRoute(context, settings, model);
      },
      onUnknownRoute: (RouteSettings settings) {
        print('CAVE: unknown route ${settings.name}');
        return MaterialPageRoute(
            builder: (BuildContext context) => ProductsPage(model));
      },
    );
  }

  Route<dynamic> defineOnGenerateRoute(
      BuildContext context, RouteSettings settings, MainModel model) {
    final List<String> pathElements = settings.name.split('/');
    // valid paths must start with '/'
    if (pathElements[0] == '' && pathElements[1] == PRODUCT) {
      final String productId = pathElements[2];
      // model.selectProduct(productId);
      return MaterialPageRoute<bool>(
        builder: (BuildContext context) => ProductPage(productId),
      );
    }
    return null;
  }

  Map<String, WidgetBuilder> defineRoutes(
      BuildContext context, MainModel model) {
    return {
      AUTHROUTE: (BuildContext context) => ScopedModelDescendant(
            builder: (BuildContext context, _, MainModel model) {
              return model.user == null ? AuthPage() : ProductsPage(model);
            },
          ),
      // Somehow this does not work:
      // AUTHROUTE: (BuildContext context) =>
      //     _model.user == null ? AuthPage() : ProductsPage(model),
      ADMINROUTE: (BuildContext context) => ProductsAdminPage(model),
      PRODUCTSROUTE: (BuildContext context) => ProductsPage(model),
    };
  }
}
