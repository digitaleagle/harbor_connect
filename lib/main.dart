import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'config/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Explicitly supply the Web Client ID retrieved from your JSON file
  //  Note: I had concerns this was sensitive, but Google says not
  //        "Even if you don't commit it, anyone who downloads your app
  //        from the App Store or visits your website can easily extract
  //        this ID by inspecting network traffic or decompiling the binary package."
  await GoogleSignIn.instance.initialize(
    serverClientId: '969764953163-es9eu9g69dp5jm40ppqoajalcmcb5m3s.apps.googleusercontent.com',
  );
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Harbor Connect',
      routerConfig: goRouter,
    );
  }
}

