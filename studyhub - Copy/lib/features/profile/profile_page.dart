import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:studyhub/features/login/login_controller/login_controller.dart';
import 'package:studyhub/features/login/login_screen.dart';
import 'package:studyhub/features/profile/profile_detail.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const primaryColor = Colors.teal; // Changed from deep indigo

  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.put(LoginController());

    return Scaffold(
      backgroundColor: Colors.teal.shade50, // Match LoginPage background
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20.h),

              ListTile(
                leading: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircleAvatar(
                        radius: 28.r,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return CircleAvatar(
                        radius: 28.r,
                        child: const Icon(Icons.person),
                      );
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final profileImageUrl = data['profileImage'] as String?;

                    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
                      return CircleAvatar(
                        radius: 28.r,
                        backgroundImage: NetworkImage(profileImageUrl),
                      );
                    } else {
                      return CircleAvatar(
                        radius: 28.r,
                        child: const Icon(Icons.person),
                      );
                    }
                  },
                ),
                title: Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
                subtitle: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return Text(
                        'No Name',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }

                    final name = snapshot.data!.get('name') ?? 'No Name';
                    return Text(
                      name,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade400,
                ),
              ),

              SizedBox(height: 30.h),

              buildOption(
                Icons.person_outline,
                'Profile',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileDetailPage(),
                    ),
                  );
                },
              ),

              buildOption(Icons.security_outlined, 'Account'),
              buildOption(Icons.settings_outlined, 'Settings'),
              buildOption(Icons.info_outline, 'About'),

              SizedBox(height: 30.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(20.w),
                  child: Row(
                    children: [
                      Icon(
                        Icons.headset_mic_outlined,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'How can we help you?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: Colors.red.shade50,
                  leading: CircleAvatar(
                    radius: 22.r,
                    backgroundColor: Colors.red.shade100,
                    child: Icon(Icons.logout, color: Colors.red, size: 20.sp),
                  ),
                  title: Text(
                    'Logout',
                    style: TextStyle(fontSize: 16.sp, color: Colors.red),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16.sp,
                    color: Colors.grey,
                  ),
                  onTap: () async {
                    await loginController.logout();
                    Get.offAll(() => const LoginPage());
                  },
                ),
              ),

              Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Privacy Policy  >  Terms  >  ',
                      style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                    ),
                    Text(
                      'English',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOption(IconData icon, String title, {VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: Colors.grey.shade100,
        leading: CircleAvatar(
          radius: 22.r,
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Icon(icon, color: primaryColor, size: 20.sp),
        ),
        title: Text(title, style: TextStyle(fontSize: 16.sp)),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16.sp,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
