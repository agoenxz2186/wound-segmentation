import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:segmentation/utilities/assets.dart';
import 'package:segmentation/views/segmentation_view.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  Future precessor(BuildContext context)async{
    FlutterNativeSplash.remove();
      await Future.delayed(const Duration(seconds: 1)).then((value){
        print('okee');
        Navigator.pushReplacement(context, 
            MaterialPageRoute(builder: (c)=>const SegmentationView()));
      });
    
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: precessor(context),
      builder: (context, snap) {
        return Scaffold(
          body: Center(
            child: Image.asset(Assets.assetsIconApp, width: 150,),
          ),
        );
      }
    );
  }
}