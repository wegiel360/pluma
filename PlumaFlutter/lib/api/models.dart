class UserProfile {
  final String username;
  final String name;
  final String bio;
  final String color;
  final String pfp;
  final String banner;
  final String joined;
  final String pw;
  final String theme;
  final String themeId;
  final int createdAt;

  const UserProfile({
    required this.username,
    this.name = '',
    this.bio = '',
    this.color = '#ffb870',
    this.pfp = 'assets/logo-kogut-500x500.png',
    this.banner = 'assets/bliss-1024p.jpg',
    this.joined = '',
    this.pw = '',
    this.theme = '',
    this.themeId = '',
    this.createdAt = 0,
  });

  factory UserProfile.fromMap(Map<String, dynamic> json) {
    return UserProfile(
      username: (json['username'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      color: (json['color'] ?? '#ffb870').toString(),
      pfp: (json['pfp'] ?? 'assets/logo-kogut-500x500.png').toString(),
      banner: (json['banner'] ?? 'assets/bliss-1024p.jpg').toString(),
      joined: (json['joined'] ?? '').toString(),
      pw: (json['pw'] ?? '').toString(),
      theme: (json['theme'] ?? '').toString(),
      themeId: (json['themeId'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? 0) is int
          ? json['createdAt'] as int
          : int.tryParse((json['createdAt'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'username': username,
        'name': name,
        'bio': bio,
        'color': color,
        'pfp': pfp,
        'banner': banner,
        'joined': joined,
        'pw': pw,
        'theme': theme,
        'themeId': themeId,
        'createdAt': createdAt,
      };

  UserProfile copyWith({
    String? bio,
    String? color,
    String? pfp,
    String? banner,
    String? name,
    String? joined,
    String? pw,
    String? theme,
    String? themeId,
  }) {
    return UserProfile(
      username: username,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      color: color ?? this.color,
      pfp: pfp ?? this.pfp,
      banner: banner ?? this.banner,
      joined: joined ?? this.joined,
      pw: pw ?? this.pw,
      theme: theme ?? this.theme,
      themeId: themeId ?? this.themeId,
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
