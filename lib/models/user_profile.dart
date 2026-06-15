// lib/models/user_profile.dart
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.createdAt,
  });

  // Convert Firebase DocumentSnapshot back into our clean model class
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  // Convert our model class into a Map that Firestore can understand
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Member {
  final String guid;
  final String firstName;
  final String lastName;
  final String? familyGuid;
  final String? userUid;
  final List<String> roleGuids;

  Member({
    required this.guid,
    required this.firstName,
    required this.lastName,
    this.familyGuid,
    this.userUid,
    this.roleGuids = const [],
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      guid: json['guid'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      familyGuid: json['familyGuid'] as String?,
      userUid: json['userUid'] as String?,
      roleGuids: (json['roleGuids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guid': guid,
      'firstName': firstName,
      'lastName': lastName,
      'familyGuid': familyGuid,
      'userUid': userUid,
      'roleGuids': roleGuids,
    };
  }
}
