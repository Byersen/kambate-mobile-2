class TeamModel {
  final String id;
  final String name;
  final String? shortName;
  final String? logoUrl;
  final String? country;

  const TeamModel({
    required this.id,
    required this.name,
    this.shortName,
    this.logoUrl,
    this.country,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Equipo Desconocido',
      shortName: json['short_name']?.toString() ?? json['shortName']?.toString(),
      logoUrl: json['logo_url']?.toString() ?? json['logoUrl']?.toString(),
      country: json['country']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'short_name': shortName,
      'logo_url': logoUrl,
      'country': country,
    };
  }
}
