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
  final String defaultCity;
  final String defaultCountry;

  const UserProfile({
    required this.username,
    this.name = '',
    this.bio = '',
    this.color = '#ffb870',
    this.pfp = 'assets/default-pfp.png',
    this.banner = 'assets/bliss-1024p.jpg',
    this.joined = '',
    this.pw = '',
    this.theme = '',
    this.themeId = '',
    this.createdAt = 0,
    this.defaultCity = '',
    this.defaultCountry = '',
  });

  factory UserProfile.fromMap(Map<String, dynamic> json) {
    return UserProfile(
      username: (json['username'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      color: (json['color'] ?? '#ffb870').toString(),
      pfp: (json['pfp'] ?? 'assets/default-pfp.png').toString(),
      banner: (json['banner'] ?? 'assets/bliss-1024p.jpg').toString(),
      joined: (json['joined'] ?? '').toString(),
      pw: (json['pw'] ?? '').toString(),
      theme: (json['theme'] ?? '').toString(),
      themeId: (json['themeId'] ?? '').toString(),
       createdAt: (json['createdAt'] ?? 0) is int
          ? json['createdAt'] as int
          : int.tryParse((json['createdAt'] ?? '0').toString()) ?? 0,
      defaultCity: (json['defaultCity'] ?? '').toString(),
      defaultCountry: (json['defaultCountry'] ?? '').toString(),
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
        'theme': theme,
        'themeId': themeId,
        'createdAt': createdAt,
        'defaultCity': defaultCity,
        'defaultCountry': defaultCountry,
      };

  Map<String, dynamic> toLocalMap() => {
        ...toMap(),
        'pw': pw,
      };

  factory UserProfile.fromLocalMap(Map<String, dynamic> json) {
    return UserProfile(
      username: (json['username'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      color: (json['color'] ?? '#ffb870').toString(),
      pfp: (json['pfp'] ?? 'assets/default-pfp.png').toString(),
      banner: (json['banner'] ?? 'assets/bliss-1024p.jpg').toString(),
      joined: (json['joined'] ?? '').toString(),
      pw: (json['pw'] ?? '').toString(),
      theme: (json['theme'] ?? '').toString(),
      themeId: (json['themeId'] ?? '').toString(),
       createdAt: (json['createdAt'] ?? 0) is int
          ? json['createdAt'] as int
          : int.tryParse((json['createdAt'] ?? '0').toString()) ?? 0,
      defaultCity: (json['defaultCity'] ?? '').toString(),
      defaultCountry: (json['defaultCountry'] ?? '').toString(),
    );
  }

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
    String? defaultCity,
    String? defaultCountry,
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
      defaultCity: defaultCity ?? this.defaultCity,
      defaultCountry: defaultCountry ?? this.defaultCountry,
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
  final int? updatedAt;
  final bool edited;
  final bool isImage;
  final bool isVideo;
  final String? imageUrl;
  final String? videoUrl;
  final String status;
  final bool isAI;

  const Message({
    required this.id,
    required this.sender,
    required this.recipient,
    required this.text,
    required this.timestamp,
    required this.createdAt,
    this.updatedAt,
    this.edited = false,
    this.isImage = false,
    this.isVideo = false,
    this.imageUrl,
    this.videoUrl,
    this.status = 'sent',
    this.isAI = false,
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
      updatedAt: json['updatedAt'] != null
          ? ((json['updatedAt'] ?? 0) is int
              ? json['updatedAt'] as int
              : int.tryParse(json['updatedAt'].toString()))
          : null,
      edited: json['edited'] == true,
      isImage: (imageUrl != null && imageUrl.isNotEmpty && text.isEmpty),
      isVideo: (videoUrl != null && videoUrl.isNotEmpty && text.isEmpty),
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      status: (json['status'] ?? 'sent').toString(),
      isAI: json['isAI'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'recipient': recipient,
        'text': text,
        'timestamp': timestamp,
        'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
        if (edited) 'edited': true,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'status': status,
        'isAI': isAI,
      };
}

class Invitation {
  final String id;
  final String from;
  final String to;
  final String status;
  final int createdAt;

  const Invitation({
    required this.id,
    required this.from,
    required this.to,
    this.status = 'pending',
    required this.createdAt,
  });

  factory Invitation.fromMap(Map<String, dynamic> json) {
    return Invitation(
      id: (json['id'] ?? '').toString(),
      from: (json['from'] ?? '').toString(),
      to: (json['to'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: (json['createdAt'] ?? 0) is int
          ? json['createdAt'] as int
          : int.tryParse((json['createdAt'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'from': from,
        'to': to,
        'status': status,
        'createdAt': createdAt,
      };
}
