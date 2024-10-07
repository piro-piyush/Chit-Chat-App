import 'package:cloud_firestore/cloud_firestore.dart';
import 'shared_pref.dart';

class DatabaseMethods {
  Future<bool> addUserDetails(Map<String, dynamic> userInfoMap,
      String id) async {
    try {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(id)
          .set(userInfoMap);
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

  Future<bool> createChatRoom(String chatRoomId,
      Map<String, dynamic> chatRoomInfoMap) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("Chat-Rooms")
          .doc(chatRoomId)
          .get();
      if (snapshot.exists) {
        print("Chat room already exists.");
        return false; // Return false if the chat room already exists
      } else {
        print("Creating a new chat room.");
        await FirebaseFirestore.instance
            .collection("Chat-Rooms")
            .doc(chatRoomId)
            .set(chatRoomInfoMap);
        return true; // Return true if created successfully
      }
    } catch (e) {
      print("Error creating chat room: $e");
      return false; // Return false on error
    }
  }

  Future<bool> addMessage(
      String chatRoomId,
      String messageId,
      Map<String, dynamic> messageInfoMap,
      String myUserName) async {
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
        .orderBy("Time-stamp", descending: true)
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

    Future<bool?> getHasDeliveredStatus(String chatRoomId,
        String messageId) async {
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
}
