import 'package:chat_app/pages/home_screen/home.dart';
import 'package:chat_app/pages/sign_in_page.dart';
import 'package:chat_app/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/shared_pref.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  String email = "", name = "", password = "", confirmPassword = "";
  bool isLoading = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> registration() async {
    if (passwordController.text == confirmPasswordController.text) {
      setState(() {
        isLoading = true;
      });

      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        String id = userCredential.user!.uid;
        String user = emailController.text.replaceAll("@gmail.com", "");
        String updateUserName = user;
        String firstLetter = user.substring(0, 1).toUpperCase();

        Map<String, dynamic> userInfoMap = {
          "Name": nameController.text,
          "E-mail": emailController.text,
          "Username": updateUserName.toUpperCase(),
          "Search-key": firstLetter,
          "Photo":
              "https://firebasestorage.googleapis.com/v0/b/chit-chat-app-593b5.appspot.com/o/default.jpeg?alt=media&token=89bae691-aeca-4b4f-90a6-d0a84baa6fa5",
          "Id": id,
          "isOnline": false,
          "Last-Seen": "online",
        };

        await DatabaseMethods().addUserDetails(userInfoMap, id);
        await SharedPrefrenceHelper().saveUserId(id);
        await SharedPrefrenceHelper().saveUserDisplayName(nameController.text);
        await SharedPrefrenceHelper().saveUserEmail(emailController.text);
        await SharedPrefrenceHelper().saveUserPhoto(
            "https://firebasestorage.googleapis.com/v0/b/chit-chat-app-593b5.appspot.com/o/default.jpeg?alt=media&token=89bae691-aeca-4b4f-90a6-d0a84baa6fa5");
        await SharedPrefrenceHelper()
            .saveUserName(updateUserName.toUpperCase());

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            "Registered Successfully",
            style: TextStyle(fontSize: 20),
          ),
          backgroundColor: Color(0xFF008069),
          duration: Duration(seconds: 2),
        ));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
          (Route<dynamic> route) => false, // This clears the entire stack
        );
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case "weak-password":
            message = "The password provided is too weak.";
            break;
          case "email-already-in-use":
            message = "The account already exists for that email.";
            break;
          case "invalid-email":
            message = "The email address is not valid.";
            break;
          default:
            message = "Registration failed, please try again.";
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontSize: 18),
          ),
          backgroundColor: Colors.red,
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            "Registration failed, please try again.",
            style: TextStyle(fontSize: 18),
          ),
          backgroundColor: Colors.red,
        ));
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          "Passwords do not match",
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height / 3,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF318776), Color(0xFF008069)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom:
                      Radius.elliptical(MediaQuery.of(context).size.width, 105),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 70),
              child: Column(
                children: [
                  const Center(
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      "Create your account",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    child: Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 30, horizontal: 20),
                        height: MediaQuery.of(context).size.height * 0.77,
                        width: MediaQuery.of(context).size.width,
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.7,
                          // minHeight:MediaQuery.of(context).size.height * 0.77,
                        ),
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
                                "Name",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              buildTextField(
                                controller: nameController,
                                icon: Icons.person,
                                hintText: "Enter your name",
                                validatorMsg: "Please enter name",
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Email",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              buildTextField(
                                controller: emailController,
                                icon: Icons.mail,
                                hintText: "Enter your email",
                                validatorMsg: "Please enter a valid email",
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please enter email";
                                  }
                                  if (!RegExp(r'^[\w-.]+@([\w-]+\.)+\w{2,4}$')
                                      .hasMatch(value)) {
                                    return "Enter a valid email";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Password",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              buildTextField(
                                controller: passwordController,
                                icon: Icons.lock,
                                hintText: "Enter your password",
                                validatorMsg: "Please enter a strong password",
                                obscureText: true,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Confirm Password",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              buildTextField(
                                controller: confirmPasswordController,
                                icon: Icons.lock,
                                hintText: "Confirm your password",
                                validatorMsg: "Please confirm password",
                                obscureText: true,
                              ),
                              const SizedBox(height: 25),
                              isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                          color: Color(0xFF008069)))
                                  : GestureDetector(
                                      onTap: () {
                                        if (_formKey.currentState!.validate()) {
                                          registration();
                                        }
                                      },
                                      child: Center(
                                        child: SizedBox(
                                          width: 130,
                                          child: Material(
                                            elevation: 5.0,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF008069),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  "Sign In",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold),
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
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignInPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Sign In",
                      style: TextStyle(color: Color(0xFF008069)),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    required String validatorMsg,
    FormFieldValidator<String>? validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return validatorMsg;
            }
            return null;
          },
      obscureText: obscureText,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        prefixIconColor: const Color(0xFF008069),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey, width: 1.5),
          // Grey border when not focused
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF008069), width: 2),
          // Same color as prefix icon when focused
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }
}
