import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import '../../services/internet_connectivity_checker.dart';
import 'app_bar_chat.dart';

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
  bool isReceiverOnline = false;
  bool hasInternet = false;
  bool isMic = true;

  @override
  void initState() {
    super.initState();
    onTheLoad();
    markOtherMessagesAsSeen(chatRoomId);
  }

  Future<void> isInternetAvailable() async {
    bool internetStatus = await isInternet();
    setState(() {
      hasInternet = internetStatus;
    });
  }

  Future<void> checkMessageStatus(String messageId) async {
    bool? hasSeen =
        await DatabaseMethods().getHasSeenStatus(chatRoomId!, messageId);
    bool? isDelivered =
        await DatabaseMethods().getHasDeliveredStatus(chatRoomId!, messageId);
    print(
        "Message seen status: $hasSeen ,Message delivered status: $isDelivered");
    setState(() {});
  }

  void markOtherMessagesAsSeen(String? chatRoomId) async {
    try {
      // Get all messages in the chat room sent by the other user
      QuerySnapshot messagesSnapshot = await FirebaseFirestore.instance
          .collection('Chat-Rooms')
          .doc(chatRoomId)
          .collection('Chats')
          .where('Send-by',
              isNotEqualTo:
                  myUserName) // Filter messages sent by the other user
          .get();

      // Update each message to set 'hasBeenSeen' to true
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var messageDoc in messagesSnapshot.docs) {
        batch.update(messageDoc.reference, {'hasBeenSeen': true});
      }
      // Commit the batch
      await batch.commit();
      print('Other user\'s messages marked as seen');
    } catch (e) {
      print('Error marking messages as seen: $e');
    }
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
    messageStream?.listen((snapshot) {
      for (var doc in snapshot.docs) {
        // bool hasSeen = doc["hasBeenSeen"];
        // bool isDelivered = doc["hasBeenDelivered"];
        checkMessageStatus(doc.id);
      }
    });
    setState(() {});
  }

  // Initialize shared prefs and messages
  Future<void> onTheLoad() async {
    await getTheSharedPref();
    checkInternetConnection();
    receiversConnectivityChecker();
    await getAndSetMessages();
  }

  Future<bool> getUserOnlineStatus(String username) async {
    try {
      return await DatabaseMethods().getUserOnlineStatusByUsername(username);
    } catch (e) {
      print("Error fetching user status: $e");
      return false; // Default to offline if user not found or an error occurs
    }
  }

  receiversConnectivityChecker() async {
    String username = chatRoomId!.replaceAll("_", "").replaceAll(myUserName!, "");
    isReceiverOnline = await getUserOnlineStatus(username);
    setState(() {});
  }

  // Check for internet connectivity
  Future<void> checkInternetConnection() async {
    isInternetAvailable();
    setState(() {});
  }

  // Generate chat room ID based on usernames
  String getChatRoomIdByUsername(String a, String b) {
    return a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)
        ? "${b}_$a"
        : "${a}_$b";
  }

  // Display individual chat message
  Widget chatMessageTile(String message, bool sendByMe, String time,
      bool hasSeen, bool hasBeenDelivered) {
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
                      sendByMe
                          ? messageStatusChecker(hasSeen, hasBeenDelivered)
                          : const SizedBox(), // Your message status icon logic
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
  messageStatusChecker(bool hasSeen, bool isDelivered) {
    if (!hasInternet) {
      return const Icon(Icons.error_outline, size: 15, color: Colors.grey);
    }

    if (isDelivered) {
      // Check if the receiver is online
      if (isReceiverOnline) {
        // Show double ticks, blue if seen, gray if not
        return Icon(
          Icons.done_all,
          color: hasSeen ? Colors.blue : Colors.grey,
          size: 15,
        );
      } else {
        // Show double ticks in gray if delivered but receiver is offline
        return const Icon(
          Icons.done,
          color: Colors.grey,
          size: 15,
        );
      }
    }
    // Show clock icon if not delivered yet
    return const Icon(Icons.access_time_rounded, size: 15, color: Colors.grey);
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

                // Check if the timestamp is null, and set a default value if necessary
                Timestamp? timestamp = ds["Time-stamp"];
                String formattedTime;

                if (timestamp != null) {
                  // Format the timestamp if it exists
                  formattedTime =
                      DateFormat('h:mm a').format(timestamp.toDate());
                } else {
                  // Default time for messages without a timestamp
                  formattedTime = "Just now";
                }

                return chatMessageTile(
                  ds["Message"],
                  myUserName == ds["Send-by"],
                  formattedTime,
                  ds["hasBeenSeen"],
                  ds["hasBeenDelivered"],
                );
              });
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
      String formattedTime = DateFormat("h:mma").format(now); // Format c

      // Map to hold the message information
      Map<String, dynamic> messageInfoMap = {
        "Message": message,
        "Send-by": myUserName,
        "Time": formattedTime, // Store formatted date
        "Time-stamp": FieldValue.serverTimestamp(), // Store formatted time
        "Photo": myProfilePic,
        "hasBeenSeen": false,
        "hasBeenDelivered": false,
      };

      // Generate a new messageId if it is null
      messageId ??= FirebaseFirestore.instance.collection("Chats").doc().id;

      // Add the message to the database
      DatabaseMethods()
          .addMessage(chatRoomId!, messageId!, messageInfoMap, myUserName!)
          .then((value) {
        // If successful, update the last message sent info
        Map<String, dynamic> lastMessageInfoMap = {
          "Last-message": message,
          "Last-message-send-time-stamp": FieldValue.serverTimestamp(),
          // Store last message date
          "Last-message-send-time": formattedTime,
          // Store last message time
          "Last-message-send-by": myUserName,
        };
        DatabaseMethods()
            .updateLastMessageSent(chatRoomId!, lastMessageInfoMap)
            .catchError((error) {
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
      appBar: appBarChatScreen(
        context,
        widget.name,
        widget.username,
        widget.profileUrl,
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
                    margin: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 12, right: 12.0, bottom: 0, top: 10),
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
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                ),
                              ),
                            ),
                            isMic
                                ? Row(
                                    children: [
                                      const Icon(Icons.attach_file,
                                          color: Colors.grey),
                                      const SizedBox(width: 15),
                                      Container(
                                        height: 25,
                                        width: 25,
                                        decoration: BoxDecoration(
                                          color: Colors.grey,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Icon(
                                          Icons.currency_rupee_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      const Icon(Icons.camera_alt_outlined,
                                          color: Colors.grey),
                                    ],
                                  )
                                : const Icon(Icons.attach_file,
                                    size: 25, color: Colors.grey),
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
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 25),
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
