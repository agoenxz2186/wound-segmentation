import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:segmentation/providers/segmentation_provider.dart';
import 'package:segmentation/views/splash_view.dart';

void main(List<String> args) {
  WidgetsBinding wb = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: wb);

  runApp( MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => SegmentationProvider(),)
    ],
    builder: (context, w) {
      return MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 58, 133, 183))
          ),
          debugShowCheckedModeBanner: false,
          home:  const SplashView()
      );
    }
  ) );
} 