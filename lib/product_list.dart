import 'package:flutter/material.dart';
import './utils/constants.dart';

class ProductList extends StatelessWidget {
  final List<Map<String, String>> products;
  final Function(int) deleteProduct;

  ProductList(this.products, {this.deleteProduct}) {
    print('[Producs Widget] Constructor');
  }

  Widget _buildProductItem(BuildContext context, int index) {
    return Card(
      child: Column(
        children: <Widget>[
          Image.asset(products[index][PRODUCTSIMAGEURL]),
          Text(products[index][PRODUCTSTITLE]),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: <Widget>[
              buildDetailsButton(context, index),
            ],
          ),
        ],
      ),
    );
  }

  FlatButton buildDetailsButton(BuildContext context, int index) {
    return FlatButton(
      child: Text('Details'),
      onPressed: () => Navigator.pushNamed<bool>(
            context,
            '$PRODUCTROUTE/$index',
          ).then((bool doDelete) {
            if (doDelete) deleteProduct(index);
          }),
    );
  }

  Widget _buildProductList() {
    if (products.length == 0) {
      // return Center(
      //   child: Text("No products foud, please add some"),
      // );
      return Container();
    }
    return ListView.builder(
      itemBuilder: _buildProductItem,
      itemCount: products.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    print('[Products Widget] Build');
    return _buildProductList();
  }
}