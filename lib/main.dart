import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'home.dart';
import 'SplashScreen.dart';
import 'tasks.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Parse().initialize(
    'xxxxxxx',
    'https://parseapi.back4app.com',
    clientKey: 'xxxxxx',
    autoSendSessionId: true,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => SplashScreen(),
        '/': (_) => HomeScreen(),
        '/tasks': (_) => TaskPage(),
      },
    );
  }
}