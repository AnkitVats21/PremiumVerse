import 'package:flutter/material.dart';
import 'home.dart';
import 'webView.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (OverscrollIndicatorNotification over) {
          over.disallowGlow();
          return;
        },
      child: MaterialApp(
        home: SafeArea(child: true ?
        MyWebView()
            :HomeScreen()
        ),
      ),
    );
  }
}

