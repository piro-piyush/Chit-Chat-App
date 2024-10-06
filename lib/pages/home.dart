import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool search = false;
  bool isLoading = false; // Loading state variable
  var queryResultSet = [];
  var tempSearchStore = [];

  String? myName, myProfilePic, myUserName, myEmail;
  Stream? chatRoomsStream;

  getTheSharedPref() async {
    myName = await SharedPrefrenceHelper().getDisplayName();
    myUserName = await SharedPrefrenceHelper().getUserName();
    myEmail = await SharedPrefrenceHelper().getUserEmail();
    myProfilePic = await SharedPrefrenceHelper().getUserPicKey();
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
    onTheLoad();
  }

  getChatRoomIdByUsername(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "a\_$b";
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
              ],
            ),
      body: Column(
        children: [
          Expanded(
            child: search
                ? searchWidget()
                : ChatRoomList(), // Display searchWidget or ChatRoomList
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

  Widget ChatRoomList() {
    return StreamBuilder(
      stream: chatRoomsStream,
      builder: (
          context,
          AsyncSnapshot snapshot,
          ) {
        return snapshot.hasData
            ? ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: snapshot.data.docs.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              DocumentSnapshot ds = snapshot.data.doc.length;
              return ChatRoomListTile(
                  lastMessage: ds.id,
                  chatRoomId: ds[""],
                  myUsername: myUserName!,
                  time: ds["Last-message-send-timeStamp"]);
            }):
        //  const Center(
        //     child: CircularProgressIndicator(),
        //   );
        const Center(child: Text("No chats yet", style: TextStyle(color: Colors.grey),));
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
              backgroundImage: AssetImage(
                data["Photo"] ?? "assets/images/default.png",
              ),
              radius: 30,
            ),
            title: Text(data["Username"] ?? "No Username"),
            subtitle: Text(data["Name"] ?? "No Name"),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () async {
              // Update the search state
              search = false;
              setState(() {});

              // Generate the chat room ID using usernames
              var chatRoomId =
                  getChatRoomIdByUsername(myUserName!, data["Username"]);

              // Check if the chat room already exists
              bool chatExists =
                  await DatabaseMethods().doesChatRoomExist(chatRoomId);

              // If chat room doesn't exist, create it
              if (!chatExists) {
                Map<String, dynamic> chatRoomInfoMap = {
                  "Users": [myUserName, data["Username"]],
                };

                // Create the chat room for the first time
                await DatabaseMethods()
                    .createChatRoom(chatRoomId, chatRoomInfoMap);
              }

              // Navigate to the chat screen regardless of whether it was created or not
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    name: data["Name"],
                    profileUrl: data["Photo"],
                    username: data["Username"],
                  ),
                ),
              );
            }),
      ),
    );
  }
}

class ChatRoomListTile extends StatefulWidget {
  final String lastMessage, chatRoomId, myUsername, time;

  const ChatRoomListTile(
      {required this.lastMessage,
      required this.chatRoomId,
      required this.myUsername,
      required this.time,
      super.key});

  @override
  State<ChatRoomListTile> createState() => _ChatRoomListTileState();
}

class _ChatRoomListTileState extends State<ChatRoomListTile> {
  String profilePicUrl = "", name = "", username = "", id = "";

  getThisUserInfo() async {
    username =
        widget.chatRoomId.replaceAll("_", "").replaceAll(widget.myUsername, "");
    QuerySnapshot querySnapshot =
        await DatabaseMethods().getUserInfo(username.toUpperCase());
    name = "${querySnapshot.docs[0]["Name"]}";
    profilePicUrl = "${querySnapshot.docs[0]["Photo"]}";
    username = "${querySnapshot.docs[0]["Username"]}";
    id = "${querySnapshot.docs[0]["Id"]}";
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              profilePicUrl == ""
                  ? const CircularProgressIndicator()
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.network(
                        profilePicUrl,
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
                      username,
                      style: const TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2,
                      child: Text(
                        widget.lastMessage,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            widget.time,
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
}
