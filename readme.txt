app name: Ping

Ping is a realtime chat app built with Flutter and Node.js. I made it to learn
how an authenticated mobile client, a REST API, MongoDB, and Socket.IO fit
together in one project.

The project now includes two development phases:

Phase 1
- Account registration and login with JWT authentication
- Session persistence on the device
- Realtime one-to-one messages with REST fallback
- MongoDB conversation history
- Live online/offline presence
- Searchable people list

Phase 2
- Group creation with selected members
- Realtime group conversations
- Group history stored in MongoDB
- Server-enforced group membership
- Sender names on group messages
- Online member counts and group member details
- Searchable group list

The Flutter client uses Provider for authentication, presence, direct
conversations, and group state. REST endpoints load persistent data and provide
a fallback when the socket is unavailable. Socket.IO handles live direct
messages, group messages, group creation events, and presence updates.

Project layout

chat_server/       Express, Socket.IO, JWT, and MongoDB REST API
flutter_chat_app/  Flutter client for Android

Run locally

1. Start the server

cd chat_server
npm install
npm run dev

The API starts at http://localhost:3000.

2. Start Flutter

cd flutter_chat_app
flutter pub get

Android emulators automatically use 10.0.2.2 to reach the host machine.
For a physical phone, pass the computer's LAN IP:

flutter run --dart-define=BACKEND_HOST=192.168.1.20

The phone and computer must be connected to the same network.

Phase 1 - complete: authentication, presence, and direct messaging
Phase 2 - complete: group creation, membership, and group conversations
Next: push notifications and message delivery/read states
