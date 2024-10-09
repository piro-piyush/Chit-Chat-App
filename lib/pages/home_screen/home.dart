import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/internet_connectivity_checker.dart';
import '../chat_screen/chat_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  bool search = false;
  bool isLoading = false; // Loading state variable
  var queryResultSet = [];
  var tempSearchStore = [];

  String? myName, myProfilePic, myUserName, myEmail,myId;
  Stream? chatRoomsStream;

  getTheSharedPref() async {
    myName = await SharedPrefrenceHelper().getDisplayName();
    myUserName = await SharedPrefrenceHelper().getUserName();
    myEmail = await SharedPrefrenceHelper().getUserEmail();
    myProfilePic = await SharedPrefrenceHelper().getUserPicKey();
    myId = await SharedPrefrenceHelper().getUserId();
    setState(() {});
  }

  onTheLoad() async {
    await getTheSharedPref();
    chatRoomsStream = await DatabaseMethods().getChatRooms();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    onInit();
  }

  Future<void> onInit() async {
    bool hasInternet = await isInternet();
    updateUserStatus(hasInternet);
    onTheLoad();
  }

  @override
  void dispose() {
    updateUserStatus(false); // Set user status to offline when app is closed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      // Set user status to offline when the app goes into background
      updateUserStatus(false);
    } else if (state == AppLifecycleState.resumed) {
      // Check for internet when the app resumes
      bool hasInternet = await isInternet();
      // Update user status based on internet connection
      updateUserStatus(hasInternet);
    }
  }

  void updateUserStatus(bool online) async {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user != null) {
      try {
        // Attempt to update user status
        if (online) {
          // User is online, update Last-Seen timestamp
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .set({
            'isOnline': true,
            'Last-Seen': FieldValue.serverTimestamp(),
            // Store current timestamp
          }, SetOptions(merge: true));
          print(
              "User status updated successfully: isOnline = true, Last-Seen updated");
        } else {
          // User is offline, just update isOnline without changing Last-Seen
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .set({
            'isOnline': false,
            // Do not update Last-Seen
          }, SetOptions(merge: true));
          print(
              "User status updated successfully: isOnline = false, Last-Seen not updated");
        }
      } catch (e) {
        // Catch and print any errors
        print("Failed to update user status: $e");
      }
    }
  }

  initiateSearch(String value) async {
    if (value.isEmpty) {
      setState(() {
        queryResultSet = [];
        tempSearchStore = [];
        isLoading = false; // Set loading state to false
      });
      return;
    }

    setState(() {
      search = true;
      isLoading = true; // Set loading state to true
    });

    var lowerCasedValue = value.toLowerCase(); // Use lower case for comparison

    // Fetch users if query result set is empty
    if (queryResultSet.isEmpty && value.isNotEmpty) {
      try {
        QuerySnapshot docs = await DatabaseMethods().search(value);
        List userList = docs.docs.map((doc) => doc.data()).toList();
        setState(() {
          queryResultSet =
              userList; // Update the queryResultSet with fetched data
          tempSearchStore =
              userList; // Initialize tempSearchStore with userList
        });
      } catch (e) {
        print("Error fetching users: $e");
      }
    } else {
      // Filter existing results based on input
      tempSearchStore = queryResultSet.where((element) {
        return element["Username"].toLowerCase().contains(lowerCasedValue) ||
            element["Name"].toLowerCase().contains(lowerCasedValue);
      }).toList();
    }

    setState(() {
      isLoading = false; // Set loading state to false after processing
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: search
          ? AppBar(
              backgroundColor: const Color(0xFF008069),
              leading: GestureDetector(
                onTap: () {
                  setState(() {
                    search = false; // Exit search mode
                  });
                },
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              title: TextField(
                onChanged: (value) {
                  initiateSearch(
                      value.toUpperCase()); // Call search logic on text change
                },
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: "Search",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                  border: InputBorder.none,
                ),
              ),
              actions: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      search = false; // Exit search mode
                    });
                  },
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () {
                      // Define the send action if necessary
                    },
                  ),
                ),
              ],
            )
          : AppBar(
              backgroundColor: const Color(0xFF008069),
              title: const Text(
                "Chit Chat",
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      search = true; // Enable search mode
                    });
                  },
                ),
                const SizedBox(
                  width: 5,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                  },
                ),
              ],
            ),
      body: Column(
        children: [
          Expanded(
            child: search
                ? searchWidget()
                : chatRoomList(), // Display searchWidget or ChatRoomList
          ),
        ],
      ),
    );
  }

  Widget searchWidget() {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(), // Loading indicator
          )
        : tempSearchStore.isEmpty
            ? const Center(
                child: Text(
                  "No users found.",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                primary: false,
                shrinkWrap: true,
                children: tempSearchStore.map((element) {
                  return buildResultCard(element); // Display search results
                }).toList(),
              );
  }

  Widget chatRoomList() {
    return StreamBuilder(
      stream: chatRoomsStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.hasData && snapshot.data.docs.isNotEmpty) {
          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: snapshot.data.docs.length, // Correct itemCount
            shrinkWrap: true,
            itemBuilder: (context, index) {
              // Access the document snapshot at the given index
              DocumentSnapshot ds = snapshot.data.docs[index];
              return ChatRoomListTile(
                lastMessage: ds["Last-message"] ?? "", // Use actual field name
                chatRoomId: ds.id, // Use document ID as chatRoomId
                myUsername: myUserName!, // Ensure myUserName is set
                time:
                    ds["Last-message-send-time"] ?? "",
                myId: myId!
              );
            },
          );
        } else {
          return const Center(
            child: Text(
              "No chats yet",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
      },
    );
  }

  Widget buildChatRow({
    required String name,
    required String img,
    required String lastMessage,
    required String lastMessageTime,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.asset(
                  img,
                  height: 70,
                  width: 70,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      lastMessage,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            lastMessageTime,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // Function to build the result card for each search result
  Widget buildResultCard(data) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        elevation: 2.0,
        borderRadius: BorderRadius.circular(10.0),
        child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                data["Photo"] ?? "assets/images/default.png",
              ),
              radius: 30,
            ),
            title: Text(myUserName == data["Username"]
                ? "${data["Username"].toString()} (You)"
                : data["Username"].toString()),
            subtitle: Text(data["Name"] ?? "No Name"),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () async {
              // Update the search state
              search = false;
              setState(() {});
              // Generate the chat room ID using usernames
              var chatRoomId = DatabaseMethods().getChatRoomIdByUIDs(myId!, data["Id"]);
              Map<String, dynamic> chatRoomInfoMap = {
                "Users": [myUserName, data["Username"]],
              };
                await DatabaseMethods()
                    .createChatRoom(chatRoomId, chatRoomInfoMap);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    name: data["Name"],
                    profileUrl: data["Photo"],
                    username: data["Username"],
                    userId: data["Id"],
                  ),
                ),
              );
            }),
      ),
    );
  }
}

class ChatRoomListTile extends StatefulWidget {
  final String lastMessage, chatRoomId, myUsername,myId, time;

  const ChatRoomListTile(
      {required this.lastMessage,
      required this.chatRoomId,
      required this.myUsername,
      required this.time,
        required this.myId,
      super.key});

  @override
  State<ChatRoomListTile> createState() => _ChatRoomListTileState();
}

class _ChatRoomListTileState extends State<ChatRoomListTile> {
  String profilePicUrl = "", name = "", username = "", id = "";

  @override
  void initState() {
    getThisUserInfo();
    super.initState();
  }

  getThisUserInfo() async {
    id = widget.chatRoomId.replaceAll("_", "").replaceAll(widget.myId, "");
    QuerySnapshot querySnapshot =
        await DatabaseMethods().getUserByIds(id);
    name = "${querySnapshot.docs[0]["Name"]}";
    profilePicUrl = "${querySnapshot.docs[0]["Photo"]}";
    username = "${querySnapshot.docs[0]["Username"]}";
    id = "${querySnapshot.docs[0]["Id"]}";
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              name: name,
              profileUrl: profilePicUrl,
              username: username,
              userId: id,
            ),
          ),
        );
      },
      leading: profilePicUrl == ""
          ? const CircularProgressIndicator()
          : ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.network(
                profilePicUrl,
                // height: 70,
                // width: 70,
                fit: BoxFit.cover,
              ),
            ),
      title: Text(
        name,
        style: const TextStyle(fontSize: 18, color: Colors.black),
      ),
      subtitle: Text(
        widget.lastMessage,
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      trailing: Column(
        children: [
          Text(
            widget.time,
            style: const TextStyle(color: Color(0xFF008069)),
          ),
        ],
      ),
    );
  }
}
