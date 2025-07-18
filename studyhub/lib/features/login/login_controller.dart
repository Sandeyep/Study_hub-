import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:studyhub/features/home/homepage.dart';

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

  Future<void> login(String email, String password) async {
    print('Logging in with: $email');
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      firebaseUser.value = userCredential.user;

      print('Login successful: ${userCredential.user?.email}');
      Get.snackbar('Success', 'Login successful');
      Get.offAll(() => const Homepage());
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? 'Login failed';
      print('Login error: ${e.code} - ${e.message}');
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String email, String password) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      firebaseUser.value = userCredential.user; // ✅ set the user
      Get.snackbar('Success', 'Account created successfully.');

      // ✅ Navigate directly to Homepage
      Get.offAll(() => const Homepage());
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? 'Registration failed';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    Get.snackbar('Logged Out', 'You have been logged out.');
  }
}
