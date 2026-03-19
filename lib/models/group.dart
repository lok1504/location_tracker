class Group {
  Group({
    required this.id,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String type;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
