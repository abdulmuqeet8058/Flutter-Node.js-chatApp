class Group {
  const Group({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberIds,
    this.createdAt,
  });

  final String id;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final String? createdAt;

  factory Group.fromJson(Map<String, dynamic> json) {
    final members = json['memberIds'] as List<dynamic>? ?? const [];

    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['ownerId'] as String,
      memberIds: members.map((id) => id.toString()).toList(),
      createdAt: json['createdAt'] as String?,
    );
  }
}
