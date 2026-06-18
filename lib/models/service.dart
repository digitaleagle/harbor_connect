class ServiceInstance {
  final String guid;
  final String serviceTypeGuid;
  final DateTime date;
  final Map<String, String> assignments; // Map<PositionGuid, MemberGuid>

  ServiceInstance({
    required this.guid,
    required this.serviceTypeGuid,
    required this.date,
    required this.assignments,
  });

  factory ServiceInstance.fromJson(Map<String, dynamic> json) {
    return ServiceInstance(
      guid: json['guid'] as String,
      serviceTypeGuid: json['serviceTypeGuid'] as String,
      date: DateTime.parse(json['date'] as String),
      assignments: (json['assignments'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as String),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guid': guid,
      'serviceTypeGuid': serviceTypeGuid,
      'date': date.toIso8601String(),
      'assignments': assignments,
    };
  }
}
