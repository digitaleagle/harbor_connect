import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'config/app_router.dart';

// Import both generated option files
import 'firebase_options.dart';
// import 'firebase_options.dart' as dev;
// import 'firebase_options_prod.dart' as prod;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read the environment variable from compile-time arguments
  //   run with:
  //       flutter run --dart-define=APP_ENV=dev
  //   build with:
  //       flutter build appbundle --dart-define=APP_ENV=prod
  // const String env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  // Select the appropriate FirebaseOptions configuration
  //   This was a good idea at first, but there's more to it. It doesn't help the google-services.json and the firebase.json
  // FirebaseOptions options;
  // if (env == 'prod') {
  //   options = prod.DefaultFirebaseOptions.currentPlatform;
  // } else {
  //   options = dev.DefaultFirebaseOptions.currentPlatform;
  // }

  try {
    await Firebase.initializeApp(
      // options: options,
        options: DefaultFirebaseOptions.currentPlatform
    );
    if (kIsWeb) {
      var clientId = "969764953163-es9eu9g69dp5jm40ppqoajalcmcb5m3s.apps.googleusercontent.com";
      if (DefaultFirebaseOptions.web.projectId == "harbor-connect-prod") {
        clientId =
        "1003878953130-rpuuaup7v1bin2bvjp15cn5eom5amuil.apps.googleusercontent.com";
      }
      await GoogleSignIn.instance.initialize(
          clientId: clientId
      );
    } else {
      // Explicitly supply the Web Client ID retrieved from your JSON file
      //  Note: I had concerns this was sensitive, but Google says not
      //        "Even if you don't commit it, anyone who downloads your app
      //        from the App Store or visits your website can easily extract
      //        this ID by inspecting network traffic or decompiling the binary package."
      await GoogleSignIn.instance.initialize(
        // serverClientId: '969764953163-es9eu9g69dp5jm40ppqoajalcmcb5m3s.apps.googleusercontent.com',
        // serverClientId: DefaultFirebaseOptions.ios.iosClientId,
      );
    }
  } catch(e) {
    print("Failed to initialize firebase and Google Sign-In: $e");
  }
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

