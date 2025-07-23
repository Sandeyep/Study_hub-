import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:studyhub/features/calender/calender_page.dart';
import 'package:studyhub/features/profile/profile_page.dart';
import 'package:studyhub/features/resource/resource_page.dart';
import 'package:studyhub/home/homepage.dart';
import 'package:studyhub/home/widget/addtaskbtn.dart';
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
  final GlobalKey<CalenderPageState> _calenderKey =
      GlobalKey<CalenderPageState>();

  List<Widget> _buildScreens() {
    return [
      const Homepage(),
      const ResourcePage(),
      const SizedBox(),
      CalenderPage(key: _calenderKey, allTasks: const []),
      const ProfilePage(),
    ];
  }

  Future<String?> _uploadToCloudinary(File file) async {
    const cloudName = 'drjnvn0mb';
    const uploadPreset = 'flutter_unsigned_preset';

    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/upload',
      );
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..fields['resource_type'] = 'auto'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonResp = json.decode(respStr);
        return jsonResp['secure_url'] as String?;
      } else {
        debugPrint('❌ Cloudinary failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Cloudinary upload error: $e');
      return null;
    }
  }

  Future<void> startUploadFlow(File file) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not signed in")));
        return;
      }

      const institutionId = 'eSO1mcR2iP2BUkdYHcFr';

      final subjectSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('institutions')
          .doc(institutionId)
          .collection('subjects')
          .get();

      if (subjectSnapshot.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No subjects available")));
        return;
      }

      final selectedSubject = await showDialog<DocumentSnapshot>(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Select Subject'),
            children: subjectSnapshot.docs
                .map(
                  (doc) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, doc),
                    child: Text(doc['name'] ?? 'Unnamed Subject'),
                  ),
                )
                .toList(),
          );
        },
      );

      if (selectedSubject == null || !mounted) return;

      final uploadedUrl = await _uploadToCloudinary(file);
      if (uploadedUrl == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Upload failed")));
        return;
      }

      final fileName = file.path.split('/').last;
      final fileExt = fileName.split('.').last.toLowerCase();
      final fileType = _mapFileType(fileExt);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('institutions')
          .doc(institutionId)
          .collection('subjects')
          .doc(selectedSubject.id)
          .collection('files')
          .add({
            'name': fileName,
            'url': uploadedUrl,
            'type': fileType,
            'uploadedAt': FieldValue.serverTimestamp(),
            'isFavorite': false,
          });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ File uploaded!")));
    } catch (e) {
      debugPrint('Upload error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
    return; // Explicit return added here
  }

  String _mapFileType(String ext) {
    switch (ext) {
      case 'pdf':
        return 'pdf';
      case 'docx':
        return 'docx';
      case 'pptx':
        return 'pptx';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return 'photo';
      default:
        return 'file';
    }
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home, size: 30),
        title: "Home",
        activeColorPrimary: Colors.tealAccent,
        inactiveColorPrimary: Colors.white,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.menu_book, size: 25),
        title: "Resources",
        activeColorPrimary: Colors.tealAccent,
        inactiveColorPrimary: Colors.white,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.add, color: Colors.white),
        title: "",
        activeColorPrimary: Colors.teal,
        inactiveColorPrimary: Colors.grey,
        onPressed: (BuildContext? context) {
          if (context == null || !context.mounted) return;
          if (Navigator.of(context).canPop()) return;

          if (_controller.index == 3) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => AddTaskBottomSheet(
                onSave: (newTask) {
                  _calenderKey.currentState?.addNewTask(newTask);
                },
              ),
            );
          } else {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => UploadFileBtn(
                onImageSelected: (file) {
                  debugPrint('📸 Image selected: ${file.path}');
                },
                onPdfSelected: (file) {
                  debugPrint('📄 File selected: ${file.path}');
                },
                userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                institutionId: 'eSO1mcR2iP2BUkdYHcFr',
                semesterId: '',
                onFileSelectedWithSubject: (File file, String subjectId) {
                  startUploadFlow(file);
                },
              ),
            );
          }
        },
      ),
      PersistentBottomNavBarItem(
        icon: SvgPicture.asset('assets/nav/clock.svg'),
        title: "Calendar",
        activeColorPrimary: Colors.tealAccent,
        inactiveColorPrimary: Colors.white,
      ),
      PersistentBottomNavBarItem(
        icon: SvgPicture.asset('assets/nav/profile.svg'),
        title: "Profile",
        activeColorPrimary: Colors.tealAccent,
        inactiveColorPrimary: Colors.white,
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
