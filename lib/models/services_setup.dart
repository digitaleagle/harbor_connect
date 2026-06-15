import 'package:uuid/uuid.dart';

class ServiceType {
  late final String guid;
  final String serviceName;
  final String dayOfTheWeek;
  final String serviceTime;
  final List<String> positionGuids;

  ServiceType({
    String? guid,
    required this.serviceName,
    required this.dayOfTheWeek,
    required this.serviceTime,
    this.positionGuids = const [],
  }) {
    if(guid == null) {
      this.guid = const Uuid().v4();
    } else {
      this.guid = guid;
    }
  }

  /// Converts a JSON map into a ServiceType instance
  factory ServiceType.fromJson(Map<String, dynamic> json) {
    return ServiceType(
      guid: json['guid'] as String,
      serviceName: json['serviceName'] as String,
      dayOfTheWeek: json['dayOfTheWeek'] as String,
      serviceTime: json['serviceTime'] as String,
      positionGuids: (json['positionGuids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Converts a ServiceType instance into a JSON map
  Map<String, dynamic> toJson() {
    return {
      'guid': guid,
      'serviceName': serviceName,
      'dayOfTheWeek': dayOfTheWeek,
      'serviceTime': serviceTime,
      'positionGuids': positionGuids,
    };
  }
}

class Position {
  final String guid;
  final String positionName;
  final String team;

  Position({
    required this.guid,
    required this.positionName,
    required this.team,
  });

  /// Converts a JSON map into a Position instance
  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      guid: json['guid'] as String,
      positionName: json['positionName'] as String,
      team: json['team'] as String,
    );
  }

  /// Converts a Position instance into a JSON map
  Map<String, dynamic> toJson() {
    return {
      'guid': guid,
      'positionName': positionName,
      'team': team,
    };
  }
}

class Role {
  final String guid;
  final String roleName;
  final bool isServiceEditor;
  final bool isMemberManager;
  final bool isSuperuser;

  Role({
    required this.guid,
    required this.roleName,
    this.isServiceEditor = false,
    this.isMemberManager = false,
    this.isSuperuser = false,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      guid: json['guid'] as String? ?? '',
      roleName: json['roleName'] as String? ?? '',
      isServiceEditor: json['isServiceEditor'] as bool? ?? false,
      isMemberManager: json['isMemberManager'] as bool? ?? false,
      isSuperuser: json['isSuperuser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guid': guid,
      'roleName': roleName,
      'isServiceEditor': isServiceEditor,
      'isMemberManager': isMemberManager,
      'isSuperuser': isSuperuser,
    };
  }
}
