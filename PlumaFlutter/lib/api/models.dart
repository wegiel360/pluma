class UserProfile {
  final String username;
  final String bio;
  final String color;
  final String pfp;
  final String banner;
  final int createdAt;

  const UserProfile({
    required this.username,
    required this.bio,
    required this.color,
    required this.pfp,
    required this.banner,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: (json['username'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      color: (json['color'] ?? '#ffb870').toString(),
      pfp: (json['pfp'] ?? 'assets/logo-kogut-500x500.png').toString(),
      banner: (json['banner'] ?? 'assets/bliss-1024p.jpg').toString(),
      createdAt: (json['createdAt'] ?? 0) is int
          ? json['createdAt'] as int
          : int.tryParse((json['createdAt'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'bio': bio,
        'color': color,
        'pfp': pfp,
        'banner': banner,
        'createdAt': createdAt,
      };

  UserProfile copyWith({
    String? bio,
    String? color,
    String? pfp,
    String? banner,
  }) {
    return UserProfile(
      username: username,
      bio: bio ?? this.bio,
      color: color ?? this.color,
      pfp: pfp ?? this.pfp,
      banner: banner ?? this.banner,
      createdAt: createdAt,
    );
  }
}

class Message {
  final String id;
  final String sender;
  final String recipient;
  final String text;
  final String timestamp;
  final int createdAt;
  final bool isImage;
  final bool isVideo;
  final String? imageUrl;
  final String? videoUrl;

  const Message({
    required this.id,
    required this.sender,
    required this.recipient,
    required this.text,
    required this.timestamp,
    required this.createdAt,
    this.isImage = false,
    this.isVideo = false,
    this.imageUrl,
    this.videoUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['imageUrl']?.toString();
    final videoUrl = json['videoUrl']?.toString();
    final text = json['text']?.toString() ?? '';
    return Message(
      id: json['id']?.toString() ?? '',
      sender: json['sender']?.toString() ?? '',
      recipient: json['recipient']?.toString() ?? '',
      text: text,
      timestamp: json['timestamp']?.toString() ?? '',
      createdAt: (json['createdAt'] ?? 0) is int
          ? json['createdAt'] as int
          : int.tryParse((json['createdAt'] ?? '0').toString()) ?? 0,
      isImage: (imageUrl != null && imageUrl.isNotEmpty && text.isEmpty),
      isVideo: (videoUrl != null && videoUrl.isNotEmpty && text.isEmpty),
      imageUrl: imageUrl,
      videoUrl: videoUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'recipient': recipient,
        'text': text,
        'timestamp': timestamp,
        'createdAt': createdAt,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
      };
}
