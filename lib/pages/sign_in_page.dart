import 'package:chat_app/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/shared_pref.dart';
import 'forget_password.dart';
import 'home_screen/home.dart';
import 'sign_up_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  String email = "", password = "", name = "", pic = "", username = "", id = "";
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  Future<void> userLogin() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please enter both email and password", style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      QuerySnapshot querySnapshot = await DatabaseMethods().getUserByEmail(emailController.text);
      if (querySnapshot.docs.isEmpty) {
        throw FirebaseAuthException(code: 'user-not-found');
      }

      name = querySnapshot.docs[0]["Name"];
      username = querySnapshot.docs[0]["Username"];
      pic = querySnapshot.docs[0]["Photo"];
      id = querySnapshot.docs[0]["Id"];

      await _saveUserDetails();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Login successful!", style: TextStyle(fontSize: 18)),
        backgroundColor: Color(0xFF008069),
      ));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
            (Route<dynamic> route) => false, // This clears the entire stack
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
      });

      String errorMessage = e.code == 'user-not-found'
          ? "User not found. Please check your email."
          : e.code == 'wrong-password'
          ? "Wrong password. Please try again."
          : "Error: ${e.message}";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage, style: const TextStyle(fontSize: 18)),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("An unexpected error occurred: ${e.toString()}", style: const TextStyle(fontSize: 18)),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveUserDetails() async {
    await SharedPrefrenceHelper().saveUserDisplayName(name);
    await SharedPrefrenceHelper().saveUserName(username);
    await SharedPrefrenceHelper().saveUserId(id);
    await SharedPrefrenceHelper().saveUserPic(pic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height / 4,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF318776),Color(0xFF008069)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.elliptical(MediaQuery.of(context).size.width, 105),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 70),
              child: Column(
                children: [
                  const Center(
                    child: Text(
                      "Sign In",
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Center(
                    child: Text(
                      "Login to your account",
                      style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    child: Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                        height: MediaQuery.of(context).size.height / 2.2,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Email",
                                style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.only(left: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(width: 1, color: Colors.black38),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextFormField(
                                  controller: emailController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter email";
                                    }
                                    return null;
                                  },
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    prefixIcon: Icon(Icons.mail, color: Color(0xFF008069)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Password",
                                style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.only(left: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(width: 1, color: Colors.black38),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextFormField(
                                  controller: passwordController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Password is too small";
                                    }
                                    return null;
                                  },
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    prefixIcon: Icon(Icons.lock, color: Color(0xFF008069)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ForgetPassword()),
                                    );
                                  },
                                  child: const Text(
                                    "Forgot Password?",
                                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : GestureDetector(
                                onTap: () {
                                  if (_formKey.currentState!.validate()) {
                                    userLogin();
                                  }
                                },
                                child: Center(
                                  child: SizedBox(
                                    width: 130,
                                    child: Material(
                                      elevation: 5.0,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF008069),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "Sign In",
                                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignUp()),
                          );
                        },
                        child: const Text("Sign Up Now!",style: TextStyle(color: Color(0xFF008069)),),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
