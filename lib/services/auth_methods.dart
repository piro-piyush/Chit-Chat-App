import 'package:firebase_auth/firebase_auth.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to get the current user
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }
}
