import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => new _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  String _email = '';
  String _password = '';
  bool _acceptTerms = false;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4), BlendMode.dstATop),
              image: AssetImage('assets/background.jpg'),
            ),
          ),
          padding: EdgeInsets.all(15.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  buildEmailField(),
                  SizedBox(height: 10.0),
                  buildPasswordField(),
                  SizedBox(height: 10.0),
                  buildAcceptTerms(),
                  SizedBox(height: 10.0),
                  buildLoginButton(context),
                  SizedBox(height: 10.0),
                  // Text('$EMAIL: $_email'),
                  // Text('$PASSWORD: $_password'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  buildAcceptTerms() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(
          Radius.circular(5.0),
        ),
      ),
      child: SwitchListTile(
        value: _acceptTerms,
        onChanged: (bool onValue) {
          setState(() {
            _acceptTerms = onValue;
          });
        },
        title: Text('Accept terms?'),
      ),
    );
  }

  TextField buildEmailField() {
    return TextField(
      decoration: InputDecoration(
        labelText: '$EMAIL:',
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: TextInputType.emailAddress,
      onChanged: (String value) {
        setState(() {
          _email = value;
        });
      },
    );
  }

  TextField buildPasswordField() {
    return TextField(
      decoration: InputDecoration(
        labelText: '$PASSWORD:',
        filled: true,
        fillColor: Colors.white,
      ),
      obscureText: true,
      onChanged: (String value) {
        setState(() {
          _password = value;
        });
      },
    );
  }

  RaisedButton buildLoginButton(BuildContext context) {
    return RaisedButton(
      color: Theme.of(context).primaryColor,
      child: Text('Login'),
      onPressed: () {
        Navigator.pushReplacementNamed(context, PRODUCTSROUTE);
      },
    );
  }
}
