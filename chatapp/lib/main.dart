
// ignore: unused_import
import 'package:chatapp/Screens/HomeScreen.dart';

// ignore: unused_import
import 'package:chatapp/authentication/CreateAccount.dart';
import 'package:chatapp/authentication/authenticate.dart';
import 'package:chatapp/firebase_options.dart';
import 'package:chatapp/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform
);
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
         home: SplashScreen(),
    );
}
}