import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:studyhub/features/profile/profile_detail.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // REMOVE this line! ScreenUtil is initialized at app root:
    // ScreenUtil.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20.h),
            ListTile(
              leading: CircleAvatar(
                radius: 28.r,
                backgroundImage: const AssetImage('assets/profile.jpg'),
              ),
              title: Text(
                'Welcome',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              ),
              subtitle: Text(
                'Marvin McKinney',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 30.h),

            // 🔽 Tap to open profile detail
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
            buildOption(Icons.settings_outlined, 'Setting'),
            buildOption(Icons.info_outline, 'About'),

            SizedBox(height: 30.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8),
                  borderRadius: BorderRadius.circular(16.r),
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
                    Text(
                      'How can we help you?',
                      style: TextStyle(color: Colors.white, fontSize: 16.sp),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

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
    );
  }

  Widget buildOption(IconData icon, String title, {VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22.r,
          backgroundColor: const Color(0xFFE0F2FE),
          child: Icon(icon, color: const Color(0xFF38BDF8), size: 20.sp),
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
