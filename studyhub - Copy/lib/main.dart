import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Add this import
import 'package:get/get.dart';
import 'package:studyhub/features/intro_screen.dart';
import 'package:studyhub/features/login/login_controller/login_controller.dart';
import 'package:studyhub/features/login/login_screen.dart';
import 'package:studyhub/home/dashboard.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Auth controller stays alive
  Get.put(LoginController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.find<LoginController>();

    return ScreenUtilInit(
      designSize: const Size(
        360,
        690,
      ), // adjust based on your design's width and height
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'StudyHub',
          home: Obx(() {
            if (controller.firebaseUser.value != null) {
              // ✅ Already logged in → Dashboard
              return const DashBoard();
            } else {
              // ✅ Not logged in → Intro pages first
              return IntroPages(
                onDone: () {
                  // ✅ After intro → go to Login
                  Get.offAll(() => const LoginPage());
                },
              );
            }
          }),
        );
      },
    );
  }
}
