import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:studyhub/features/focus/focus_page.dart';
import 'package:studyhub/features/profile/profile_page.dart';
import 'package:studyhub/features/resource/resource_page.dart';
import 'package:studyhub/home/homepage.dart';
import 'package:studyhub/home/widget/upload_file_btn.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({super.key});

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  final PersistentTabController _controller = PersistentTabController(
    initialIndex: 0,
  );

  // ✅ Shared tasks list
  final List<Map<String, dynamic>> allTasks = [
    {
      'date': DateTime.now(),
      'title': 'Do Math Homework',
      'time': 'Today At 16:45',
      'tags': 'University',
      'tagColor': Colors.blue,
      'count': 1,
      'completed': false,
    },
    {
      'date': DateTime.now().add(const Duration(days: 1)),
      'title': 'Prepare slides',
      'time': 'Tomorrow At 10:00',
      'tags': 'Work',
      'tagColor': Colors.green,
      'count': 2,
      'completed': false,
    },
  ];

  List<Widget> _buildScreens() {
    return [
      const Homepage(),
      ResourcePage(),
      const SizedBox(),
      const FocusPage(),
      const ProfilePage(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: SvgPicture.asset('assets/nav/home.svg'),
        title: ("Home"),
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: SvgPicture.asset('assets/nav/calender.svg'),
        title: ("Resources"),
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.add, color: Colors.white),
        title: "",
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
        onPressed: (context) {
          if (Navigator.of(context!).canPop()) {
            return; // Prevent multiple sheets
          }

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => UploadFileBtn(
              onImageSelected: (file) {
                print('📸 Image selected: ${file.path}');
              },
              onPdfSelected: (file) {
                print('📄 File selected: ${file.path}');
              },
            ),
          );
        },
      ),

      PersistentBottomNavBarItem(
        icon: SvgPicture.asset('assets/nav/clock.svg'),
        title: ("Focus"),
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: SvgPicture.asset('assets/nav/profile.svg'),
        title: ("Profile"),
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      navBarHeight: 70,
      backgroundColor: const Color(0xff363636),
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      navBarStyle: NavBarStyle.style15,
    );
  }
}
