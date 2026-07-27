class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String createdAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
  });

  bool isMine(String userId) => senderId == userId;

  DateTime get sentAt =>
      DateTime.tryParse(createdAt)?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      text: json['text'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
