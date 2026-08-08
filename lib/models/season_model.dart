class SeasonModel {
  final String id;
  final String name;
  final String slug;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;

  const SeasonModel({
    required this.id,
    required this.name,
    required this.slug,
    this.startDate,
    this.endDate,
    this.isCurrent = true,
  });

  factory SeasonModel.fromJson(Map<String, dynamic> json) {
    return SeasonModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString())
          : (json['startDate'] != null
              ? DateTime.tryParse(json['startDate'].toString())
              : null),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString())
          : (json['endDate'] != null
              ? DateTime.tryParse(json['endDate'].toString())
              : null),
      isCurrent: json['is_current'] == true || json['isCurrent'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_current': isCurrent,
    };
  }
}
