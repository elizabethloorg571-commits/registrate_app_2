import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:running_app/src/utils/navigator_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const name = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool showImage = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
    var d = const Duration(seconds: 4);
    Future.delayed(d, () async {
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('hasSplashed', true);
      // prefs.setBool('isLoggedIn', true);

      // GoRouter.of(
      //   navigatorKey.currentContext!,
      // ).pushReplacementNamed('/onboarding');

      GoRouter.of(navigatorKey.currentContext!).pushReplacementNamed('/');
    });
  }

  void _startAnimation() async {
    await Future.delayed(
      Duration(milliseconds: 600),
    ); // Small delay before showing image
    setState(() => showImage = true); // Show the logo
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
      },
      child: Scaffold(
        body: Container(
          width: size.width,
          height: size.height,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/splash_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Lottie.asset(
              'assets/json/animations/man_running.json',
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
        ),
      ),
    );
  }
}
