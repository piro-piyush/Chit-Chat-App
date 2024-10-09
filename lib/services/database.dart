import 'package:cloud_firestore/cloud_firestore.dart';
import 'shared_pref.dart';

class DatabaseMethods {

  Future<bool> addUserDetails(Map<String, dynamic> userInfoMap, String id) async {
    try {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(id)
          .set(userInfoMap);
      print("User have been added succfully");
      return true; // Return true on successful addition
    } catch (e) {
      print("Error adding user details: $e");
      return false; // Return false on failure
    }
  }

  Future<QuerySnapshot> getUserByEmail(String email) async {
    try {
      return await FirebaseFirestore.instance
          .collection("Users")
          .where("E-mail", isEqualTo: email)
          .get();
    } catch (e) {
      print("Error fetching user by email: $e");
      return await FirebaseFirestore.instance.collection("Users")
          .limit(0)
          .get(); // Return an empty QuerySnapshot
    }
  }

  Future<QuerySnapshot> getUserByUsername(String username) async {
    try {
      return await FirebaseFirestore.instance
          .collection("Users")
          .where("Username", isEqualTo: username)
          .get();
    } catch (e) {
      print("Error fetching user by username: $e");
      return await FirebaseFirestore.instance.collection("Users")
          .limit(0)
          .get(); // Return an empty QuerySnapshot
    }
  }

  Future<QuerySnapshot> getUserByIds(String id) async {
    try {
      return await FirebaseFirestore.instance
          .collection("Users")
          .where("Id", isEqualTo: id)
          .get();
    } catch (e) {
      print("Error fetching user by Id: $e");
      return await FirebaseFirestore.instance.collection("Users")
          .limit(0)
          .get(); // Return an empty QuerySnapshot
    }
  }

  Future<QuerySnapshot> search(String query) async {
    try {
      return await FirebaseFirestore.instance
          .collection("Users")
          .where("Username", isGreaterThanOrEqualTo: query)
          .where("Username", isLessThanOrEqualTo: '$query\uf8ff')
          .get();
    } catch (e) {
      print("Error during search: $e");
      return await FirebaseFirestore.instance.collection("Users")
          .limit(0)
          .get(); // Return an empty QuerySnapshot
    }
  }

  String getChatRoomIdByUIDs(String uid1, String uid2) {
    // Sort UIDs alphabetically to ensure consistency
    List<String> uids = [uid1, uid2];
    uids.sort(); // Sorts UIDs alphabetically
    return "${uids[0]}_${uids[1]}";
  }

  Future<bool> createChatRoom(String chatRoomId, Map<String, dynamic> chatRoomInfoMap) async {
    try {
      // Check if the chat room already exists
      final snapshot = await FirebaseFirestore.instance
          .collection("Chat-Rooms")
          .doc(chatRoomId)
          .get();
      if (snapshot.exists) {
        // Chat room already exists
        print("Chat room already exists.");
        return true; // Indicating the chat room exists
      } else {
        // Create a new chat room
        print("Creating a new chat room.");
        await FirebaseFirestore.instance
            .collection("Chat-Rooms")
            .doc(chatRoomId)
            .set(chatRoomInfoMap);
        return true; // Indicating the chat room was created successfully
      }
    } catch (e) {
      // Error handling
      print("Error creating chat room: $e");
      return false; // Return false on error
    }
  }

  Future<bool> addMessage(String chatRoomId, String messageId, Map<String, dynamic> messageInfoMap, String myUserName) async {
    try {
      // Add message to the Firestore collection
      await FirebaseFirestore.instance
          .collection("Chat-Rooms")
          .doc(chatRoomId)
          .collection("Chats")
          .doc(messageId)
          .set(messageInfoMap);

      print("Message added successfully.");

      // Get all messages in the chat room sent by the current user
      QuerySnapshot messagesSnapshot = await FirebaseFirestore.instance
          .collection('Chat-Rooms')
          .doc(chatRoomId)
          .collection('Chats')
          .where('Send-by', isEqualTo: myUserName)
          .get();

      // Batch update to mark messages as delivered
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var messageDoc in messagesSnapshot.docs) {
        batch.update(messageDoc.reference, {'hasBeenDelivered': true});
      }
      // Commit the batch update
      await batch.commit();
      print('Messages marked as delivered');

      return true; // Success
    } catch (e) {
      print('Error occurred: $e');
      return false; // Return false if any error occurs
    }
  }

  Future<void> updateLastMessageSent(String chatRoomId, Map<String, dynamic> lastMessageInfoMap) async {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('Chat-Rooms')
        .doc(chatRoomId);

    try {
      // Check if the document exists
      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // If the document exists, update it
        await docRef.update(lastMessageInfoMap);
      } else {
        // If the document does not exist, create it with some default data
        await docRef.set(lastMessageInfoMap);
      }
      print("Last message updated successfully.");
    } catch (e) {
      print("Error updating last message: $e");
    }
  }

  Future<Stream<QuerySnapshot>> getChatRowMessages(String chatRoomId) async {
    return FirebaseFirestore.instance
        .collection("Chat-Rooms")
        .doc(chatRoomId)
        .collection("Chats")
        .orderBy("Time-stamp", descending: true)
        .snapshots();
  }

  Future<QuerySnapshot> getUserInfo(String username) async {
    try {
      return await FirebaseFirestore.instance
          .collection("Users")
          .where("Username", isEqualTo: username)
          .get();
    } catch (e) {
      print("Error fetching user info: $e");
      return await FirebaseFirestore.instance.collection("Users")
          .limit(0)
          .get(); // Return an empty QuerySnapshot
    }
  }

  Future<Stream<QuerySnapshot>> getChatRooms() async {
    String? myUserName = await SharedPrefrenceHelper().getUserName();
    return FirebaseFirestore.instance
        .collection("Chat-Rooms")
        .orderBy("Last-message-send-time-stamp", descending: true)
        .where("Users", arrayContains: myUserName!)
        .snapshots();
  }

  Future<bool> doesChatRoomExist(String chatRoomId) async {
    try {
      final chatRoom = await FirebaseFirestore.instance.collection("Chat-Rooms")
          .doc(chatRoomId)
          .get();
      return chatRoom.exists;
    } catch (e) {
      print("Error checking chat room existence: $e");
      return false; // Return false on error
    }
  }

  Future<bool?> getHasSeenStatus(String chatRoomId, String messageId) async {
    try {
      // Fetch the specific message document by ID
      DocumentSnapshot messageDoc = await FirebaseFirestore.instance
          .collection('Chat-Rooms')
          .doc(chatRoomId)
          .collection('Chats')
          .doc(messageId)
          .get();

      // Check if the document exists
      if (messageDoc.exists) {
        // Return the hasBeenSeen status
        return messageDoc['hasBeenSeen'];
      } else {
        print("Message not found");
        return null; // Message not found
      }
    } catch (e) {
      print("Error fetching hasBeenSeen status: $e");
      return null; // Return null on error
    }
  }

    Future<bool?> getHasDeliveredStatus(String chatRoomId, String messageId) async {
      try {
        // Fetch the specific message document by ID
        DocumentSnapshot messageDoc = await FirebaseFirestore.instance
            .collection('Chat-Rooms')
            .doc(chatRoomId)
            .collection('Chats')
            .doc(messageId)
            .get();

        // Check if the document exists
        if (messageDoc.exists) {
          // Return the hasBeenSeen status
          return messageDoc['hasBeenDelivered'];
        } else {
          print("Message not found");
          return null; // Message not found
        }
      } catch (e) {
        print("Error fetching hasBeenDelivered status: $e");
        return null; // Return null on error
      }
    }

  Future<bool> getUserOnlineStatusByUsername(String username) async {
    try {
      // Fetch user document where 'Username' matches the provided username
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection("Users")
          .where("Username", isEqualTo: username)
          .get();

      // If a user document is found
      if (userSnapshot.docs.isNotEmpty) {
        // Get the first document (since usernames should be unique)
        DocumentSnapshot userDoc = userSnapshot.docs.first;
        // Check and return 'isOnline' status, defaulting to false if not found
        bool isOnline = userDoc['isOnline'] ?? false;
        return isOnline;
      } else {
        // User not found, return false
        print("User not found.");
        return false;
      }
    } catch (e) {
      // Error occurred while fetching user status
      print("Error fetching user online status: $e");
      return false; // Return false in case of an error
    }
  }
}
