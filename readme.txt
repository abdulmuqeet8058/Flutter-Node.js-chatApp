app name : ping

Ping is a small realtime chat app built with Flutter and Node.js. I made it to
learn how an authenticated mobile client, a REST API, and a socket.io connection
fit together in one project.

This repository currently represents parte 1  one-to-one
conversations. Group chat is intentionally reserved for Phase 2.

Account registration and login with JWT authentication
Session persistence on the device
Realtime one-to-one messages with REST fallback
Conversation history stored in MongoDB
Live online/offline presence
Searchable people list
Responsive Material 3 interface with light and dark themes

Project layout
chat_server/       express.js, socket.io, JWT, and mongodb Restful api
flutter_chat_app/  flutter client for Android and ios 


The client uses restful api for authentication, user discovery, and message history.
Socket.IO handles new messages and presence updates while the app is open.

Run locally

1. Start the server

cd chat_server
npm install

npm run dev

The API starts on `http://localhost:3000`.

2. Start Flutter

cd flutter_chat_app
flutter pub get

Android emulators automatically use "10.0.2.2" to reach the host machine.
for a physical phone, pass the computer's LAN IP:

flutter run --dart-define=BACKEND_HOST=192.168.1.20

The phone and computer must be connected to the same network.

Phase 1 — complete:** authentication, presence, and direct messaging
Phase 2 — planned:** group creation and group conversations
next part: group chat and push notifications