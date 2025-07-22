import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:studyhub/auth.dart';
import 'package:studyhub/features/afterlogin_into/complete.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var firebaseUser = Rx<User?>(null);

  var isLoading = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
  }

  // 🔐 Login Function
  Future<void> login(String email, String password) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      firebaseUser.value = userCredential.user;

      Get.snackbar('Success', 'Login successful');

      // ✅ Let AuthWrapper handle where to go
      Get.offAll(() => const AuthWrapper());

    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? 'Login failed';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  // 🆕 Register Function
  Future<void> register(String email, String password) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      firebaseUser.value = userCredential.user;

      Get.snackbar('Success', 'Account created successfully.');

      // ✅ For new user, go to CompleteProfilePage directly
      Get.offAll(() => const CompleteProfilePage());

    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? 'Registration failed';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  // 🚪 Logout Function
  Future<void> logout() async {
    await _auth.signOut();
    Get.snackbar('Logged Out', 'You have been logged out.');
  }
}
