
import 'package:flutter/material.dart';

import '../home_screen/home.dart';

AppBar appBarChatScreen(BuildContext context, String name, String username, String profileUrl){
  return AppBar(
    backgroundColor: const Color(0xFF008069),
    title: Text(
      name,
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 24,
        fontWeight: FontWeight.w400,
      ),
    ),
    leadingWidth: MediaQuery.of(context).size.width / 5.27,
    leading: Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
            );
          },
          child: const Icon(Icons.arrow_back_rounded,
              size: 28, color: Color(0xFFFFFFFF)),
        ),
        const SizedBox(
          width: 10,
        ),
        ClipOval(
          child: Image.asset(
            profileUrl,
            height: 40,
            width: 40,
            fit: BoxFit.cover,
          ),
        )
      ],
    ),
    actions: [
      InkWell(
          onTap: () {},
          child: const Icon(IconData(0xe6a8, fontFamily: 'MaterialIcons'),
              color: Colors.white, size: 25)),
      const SizedBox(
        width: 15,
      ),
      InkWell(
          onTap: () {},
          child: const Icon(Icons.call, color: Colors.white, size: 22)),
      const SizedBox(
        width: 15,
      ),
      InkWell(
          onTap: () {},
          child: const Icon(
            Icons.more_vert,
            color: Colors.white,
            size: 25,
          ))
    ],
  );
}