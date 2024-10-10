# Chit Chat App

Chit Chat is a real-time chat application built using Flutter and Firebase. It enables users to send and receive messages, check message delivery and read statuses (like WhatsApp ticks), and view the online/offline status of the participants. The app provides a smooth chat interface with custom UI, chat bubbles, message timestamps, and more.  

## Table of Contents
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Installation](#installation)
- [Firebase Setup](#firebase-setup)
- [Usage](#usage)
- [Screenshots](#screenshots)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## Features

- **Real-time Messaging**: Users can send and receive messages instantly with real-time updates.
- **Message Status**: Check message delivery and read statuses (single tick, double ticks, and blue ticks).
- **Online Status**: Users can see when the recipient is online.
- **Typing Indicator**: Display when the other user is typing (future feature).
- **Chat Rooms**: Users are auto-enrolled in a chat room based on their usernames.
- **Message Seen Feature**: Messages are marked as seen once the recipient opens the chat.
- **Internet Connectivity Check**: Messages indicate when there’s no internet connection, and they will retry once the connection is back.
- **Profile Setup**: Users can set their profile picture and display name.
- **Custom UI**: Beautifully designed chat interface with message bubbles, timestamps, and more.
  
## Tech Stack

- **Flutter**: Frontend framework for building beautiful and responsive mobile applications for Android and iOS.
- **Firebase Firestore**: Cloud-based NoSQL database used for real-time chat data storage.
- **Firebase Authentication**: Used for user authentication (email and password).
- **Firebase Storage**: Stores user profile pictures.
- **Shared Preferences**: For storing user login data locally for faster subsequent logins.

## Installation

To get started with the **Chit Chat** app locally, follow these steps:

### Prerequisites
- Flutter installed on your system. If not, follow [Flutter installation guide](https://flutter.dev/docs/get-started/install).
- A Firebase project setup (detailed in the next section).

### Steps

1. **Clone the Repository:**

    ```bash
    git clone https://github.com/piro-piyush/Chit-Chat-App
    ```

2. **Navigate to the Project Directory:**

    ```bash
    cd chit-chat
    ```

3. **Install Dependencies:**

    Run the following command to install the necessary packages:

    ```bash
    flutter pub get
    ```

4. **Configure Firebase:**

    Set up Firebase for the project (see [Firebase Setup](#firebase-setup) section below).

5. **Run the Application:**

    Start the application by running:

    ```bash
    flutter run
    ```

6. **Build for Release (Optional):**

    For building a release version for Android or iOS:

    ```bash
    flutter build apk   # For Android
    flutter build ios   # For iOS
    ```

## Firebase Setup

1. **Create a Firebase Project:**

    Visit the [Firebase Console](https://console.firebase.google.com/) and create a new project.

2. **Add Android & iOS Apps to Firebase:**

    - **Android**: Download the `google-services.json` file and place it in the `android/app` directory.
    - **iOS**: Download the `GoogleService-Info.plist` file and place it in the `ios/Runner` directory.

3. **Enable Firebase Services:**

    - Go to the Firebase console and enable **Cloud Firestore**, **Firebase Authentication** (with Email/Password), and **Firebase Storage**.

4. **Firestore Rules:**

    Set Firestore rules to ensure security:

    ```bash
    service cloud.firestore {
      match /databases/{database}/documents {
        match /Chat-Rooms/{chatRoomId} {
          allow read, write: if request.auth != null;
        }
      }
    }
    ```

5. **Firebase Dependencies:**

    Make sure your `pubspec.yaml` includes:

    ```yaml
    dependencies:
      firebase_core: latest_version
      cloud_firestore: latest_version
      firebase_auth: latest_version
      firebase_storage: latest_version
      shared_preferences: latest_version
    ```

## Usage

1. **User Registration:**

    - Users can sign up with an email and password and create a profile with a username and profile picture.
    
2. **Sending Messages:**

    - Select a user to start a chat. Messages are sent in real-time and marked as delivered and seen.

3. **Message Status:**

    - Single tick indicates the message has been sent.
    - Double grey ticks indicate the message has been delivered.
    - Double blue ticks indicate the message has been read.

4. **Chat Room Creation:**

    - When a user initiates a chat, a chat room is automatically created based on their username and the recipient's username.

5. **Online Status:**

    - A user’s online status is indicated on the chat screen, and it changes dynamically based on their current activity.

## Screenshots

| Chat Screen | Message Status |
|-------------|----------------|
| ![Chat Screen](https://via.placeholder.com/300x600) | ![Message Status](https://via.placeholder.com/300x600) |

## Contributing

Contributions are always welcome! Please feel free to fork this repository and submit pull requests.

1. **Fork the repository**
2. **Create a new branch** (`git checkout -b feature-branch`)
3. **Commit your changes** (`git commit -m 'Add some feature'`)
4. **Push to the branch** (`git push origin feature-branch`)
5. **Open a pull request**

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For any questions, feel free to reach out:

- **Name**: Piyush
- **Email**: piyush72717272@gmail.com
- **GitHub**: [github.com/piro-piyush](https://github.com/piro-piyush).