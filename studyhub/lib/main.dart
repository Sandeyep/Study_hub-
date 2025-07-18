import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studyhub/features/home/homepage.dart';
import 'package:studyhub/features/intro_screen.dart';
import 'package:studyhub/features/login/login_controller.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Make controller permanent so auth state persists
  Get.put(LoginController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.find<LoginController>();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App',
      home: Obx(() {
        if (controller.firebaseUser.value != null) {
          return const Homepage();
        } else {
          return const IntroPages();
        }
      }),
    );
  }
}
