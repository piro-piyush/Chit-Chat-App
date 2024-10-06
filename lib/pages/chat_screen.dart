import 'package:chat_app/pages/home.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:random_string/random_string.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import '../services/internet_connectivity_checker.dart';

class ChatScreen extends StatefulWidget {
  final String name, profileUrl, username;

  const ChatScreen({
    required this.name,
    required this.profileUrl,
    required this.username,
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  String? myUserName, myProfilePic, myName, myEmail, messageId, chatRoomId;
  Stream? messageStream;
  bool isDelivered = true;
  bool hasSeen = false;
  bool isOnline = false;
  bool isConnected = true;
  bool isMic = true;

  @override
  void initState() {
    super.initState();
    onTheLoad();
  }

  void toggleChatSuffix() {
    setState(() {
      if (messageController.text.isNotEmpty) {
        isMic = false;
      } else if (messageController.text.isEmpty) {
        isMic = true;
      }
    });
  }

  // Fetch shared preferences to get user details
  Future<void> getTheSharedPref() async {
    myName = await SharedPrefrenceHelper().getDisplayName();
    myUserName = await SharedPrefrenceHelper().getUserName();
    myEmail = await SharedPrefrenceHelper().getUserEmail();
    myProfilePic = await SharedPrefrenceHelper().getUserPicKey();
    chatRoomId = getChatRoomIdByUsername(widget.username, myUserName!);
    setState(() {});
  }

  // Fetch messages for the chat room
  Future<void> getAndSetMessages() async {
    messageStream = await DatabaseMethods().getChatRowMessages(chatRoomId!);
    setState(() {});
  }

  // Initialize shared prefs and messages
  Future<void> onTheLoad() async {
    await getTheSharedPref();
    await getAndSetMessages();
  }

  // Check for internet connectivity
  Future<void> checkInternetConnection() async {
    isConnected = await isInternet();
    setState(() {});
  }

  // Generate chat room ID based on usernames
  String getChatRoomIdByUsername(String a, String b) {
    return a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)
        ? "${b}_$a"
        : "${a}_$b";
  }

  // Display individual chat message
  Widget chatMessageTile(String message, bool sendByMe, String time) {
    return Row(
      mainAxisAlignment:
      sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        ChatBubble(
          // Clipper requires correct syntax, ternary operator needs the format for both bubble types.
          clipper: ChatBubbleClipper2(
              type:
              sendByMe ? BubbleType.sendBubble : BubbleType.receiverBubble),
          backGroundColor:
          sendByMe ? const Color(0xFFE7FEDB) : const Color(0xfff6f6f6),
          margin: const EdgeInsets.only(top: 10),
          child: IntrinsicWidth(
            // Ensure the container resizes based on content width
            child: Container(
              constraints: BoxConstraints(
                minWidth: 40, // Minimum width for the bubble
                maxWidth: MediaQuery.of(context).size.width *
                    0.45, // Max width is 45% of screen
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87 // Adjust color based on sender
                    ),
                  ),
                  const SizedBox(height: 0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 5),
                      messageStatusChecker(), // Your message status icon logic
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Show message status (double ticks, single tick, etc.)
  Widget messageStatusChecker() {
    if (isConnected == true) {
      if (isDelivered == true) {
        if (isOnline == true) {
          return Icon(Icons.done_all,
              color: hasSeen ? Colors.blue : Colors.grey,
              size: 15); // Seen or delivered
        } else {
          return const Icon(
            Icons.done,
            size: 15,
            color: Colors.grey,
          ); // Delivered but not online
        }
      } else {
        return const Icon(
          Icons.access_time_rounded,
          size: 15,
          color: Colors.grey,
        ); // Message not delivered yet
      }
    } else {
      return const Icon(Icons.access_time_rounded,
          size: 15, color: Colors.grey); // Not connected to the internet
    }
  }

  // Build chat messages using StreamBuilder
  Widget chatMessage() {
    return StreamBuilder(
      stream: messageStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error loading messages"));
        } else if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
          return const Center(child: Text("No messages yet"));
        } else {
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 90, top: 130),
            itemCount: snapshot.data.docs.length,
            reverse: true,
            itemBuilder: (context, index) {
              DocumentSnapshot ds = snapshot.data.docs[index];
              Timestamp timestamp = ds["Time"];
              String formattedTime = DateFormat('h:mm a').format(timestamp.toDate()); // Format Timestamp
              return chatMessageTile(
                  ds["Message"], myUserName == ds["Send-by"], formattedTime);
            },
          );
        }
      },
    );
  }

  // Send a message
  void addMessage(bool sendClicked) {
    if (messageController.text.isNotEmpty) {
      // Prepare message data
      String message = messageController.text;
      messageController.clear(); // Clear the message input after sending

      DateTime now = DateTime.now();
      String formattedDate = DateFormat("yMMMd").format(now); // Format current date
      String formattedTime = DateFormat("h:mma").format(now); // Format current time

      // Map to hold the message information
      Map<String, dynamic> messageInfoMap = {
        "Message": message,
        "Send-by": myUserName,
        "Date": formattedDate, // Store formatted date
        "Time": formattedTime, // Store formatted time
        "Photo": myProfilePic,
      };

      // Generate a new messageId if it is null
      messageId ??= randomAlphaNumeric(10);

      // Add the message to the database
      DatabaseMethods().addMessage(chatRoomId!, messageId!, messageInfoMap).then((value) {
        // If successful, update the last message sent info
        Map<String, dynamic> lastMessageInfoMap = {
          "Last-message": message,
          "Last-message-send-date": formattedDate, // Store last message date
          "Last-message-send-time": formattedTime, // Store last message time
          "Last-message-send-by": myUserName,
        };

        DatabaseMethods().updateLastMessageSent(chatRoomId!, lastMessageInfoMap).catchError((error) {
          print("Error updating last message: $error");
        });

        // Reset the messageId only if sendClicked is true
        if (sendClicked) {
          messageId = null;
        }
      }).catchError((error) {
        print("Error adding message: $error");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF008069),
        title: Text(
          widget.name,
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
                widget.profileUrl,
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
      ),
      body: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 0),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
                color: Colors.white,
                image: DecorationImage(
                    image: AssetImage(
                      "assets/images/chatBg.jpg",
                    ),
                    fit: BoxFit.fitHeight)),
            child: chatMessage(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 55,
                    width: (MediaQuery.of(context).size.width / 10) * 9,
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 12.0, bottom: 0, top: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.emoji_emotions_outlined,
                              size: 26,
                              color: Colors.grey,
                            ),
                            Expanded(
                              child: TextField(
                                controller: messageController,
                                onChanged: (value) {
                                  setState(() {
                                    toggleChatSuffix();
                                  });
                                },
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Message",
                                  hintStyle: TextStyle(color: Colors.black45),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                ),
                              ),
                            ),
                            isMic
                                ? Row(
                              children: [
                                const Icon(Icons.attach_file, color: Colors.grey),
                                const SizedBox(width: 15),
                                Container(
                                  height: 25,
                                  width: 25,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.currency_rupee_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                const Icon(Icons.camera_alt_outlined, color: Colors.grey),
                              ],
                            )
                                : const Icon(Icons.attach_file, size: 25, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 55,
                  width: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFF008069),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (!isMic) {
                        setState(() {
                          addMessage(true);
                        });
                      } else {
                        // Add mic recording logic if needed
                      }
                    },
                    child: Center(
                      child: isMic
                          ? const Icon(Icons.mic, color: Colors.white, size: 28)
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 25),
                    ),
                  ),
                )
              ],
            ),
          )

        ],
      ),
    );
  }
}