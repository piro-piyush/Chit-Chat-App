import 'package:chat_app/pages/home.dart';
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
        String updateUserName =
            user.replaceFirst(user[0], user[0].toUpperCase());
        String firstLetter = user.substring(0, 1).toUpperCase();

        Map<String, dynamic> userInfoMap = {
          "Name": nameController.text,
          "E-mail": emailController.text,
          "Username": updateUserName.toUpperCase(),
          "Search-key": firstLetter,
          "Photo": "assets/images/default.png",
          "Id": id,
        };

        await DatabaseMethods().addUserDetails(userInfoMap, id);
        await SharedPrefrenceHelper().saveUserId(id);
        await SharedPrefrenceHelper().saveUserDisplayName(nameController.text);
        await SharedPrefrenceHelper().saveUserEmail(emailController.text);
        await SharedPrefrenceHelper().saveUserPic("assets/images/default.png");
        await SharedPrefrenceHelper()
            .saveUserName(updateUserName.toUpperCase());

        ScaffoldMessenger.of(mounted as BuildContext).showSnackBar(const SnackBar(
          content: Text(
            "Registered Successfully",
            style: TextStyle(fontSize: 20),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ));
        Navigator.pushReplacement(
          mounted as BuildContext,
          MaterialPageRoute(builder: (context) => const Home()),
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

        ScaffoldMessenger.of(mounted as BuildContext).showSnackBar(SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontSize: 18),
          ),
          backgroundColor: Colors.red,
        ));
      } catch (e) {
        ScaffoldMessenger.of(mounted as BuildContext).showSnackBar(const SnackBar(
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
      ScaffoldMessenger.of(mounted as BuildContext).showSnackBar(const SnackBar(
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
              height: MediaQuery.of(context).size.height / 4,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7f30fe), Color(0xFF6380fb)],
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
                        color: Color(0xFFbbb0ff),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 20),
                    child: Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 30, horizontal: 20),
                        height: MediaQuery.of(context).size.height * 0.77,
                        width: MediaQuery.of(context).size.width,
                        constraints: BoxConstraints(
                          maxHeight:
                              MediaQuery.of(context).size.height * 0.7,
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
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$')
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
                                validatorMsg:
                                    "Please enter a strong password",
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
                                      child: CircularProgressIndicator())
                                  : GestureDetector(
                                      onTap: () {
                                        if (_formKey.currentState!
                                            .validate()) {
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
                                              padding:
                                                  const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color:
                                                    const Color(0xFF6380fb),
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
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const SignInPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign In",
                          style: TextStyle(color: Colors.purple),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }
}
