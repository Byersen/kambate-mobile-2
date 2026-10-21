class ParticipantModel {
  final String id;
  final String name;
  final String? slug;
  final String? shortName;
  final String? logoUrl;
  final String? photoUrl;
  final String? country;
  final String? record;
  final String? sportId;

  const ParticipantModel({
    required this.id,
    required this.name,
    this.slug,
    this.shortName,
    this.logoUrl,
    this.photoUrl,
    this.country,
    this.record,
    this.sportId,
  });

  String get displayName => shortName ?? name;

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Participante',
      slug: json['slug']?.toString(),
      shortName: json['short_name']?.toString() ?? json['shortName']?.toString(),
      logoUrl: json['logo_url']?.toString() ?? json['logoUrl']?.toString(),
      photoUrl: json['photo_url']?.toString() ??
          json['photoUrl']?.toString() ??
          json['logo_url']?.toString() ??
          json['logoUrl']?.toString(),
      country: json['country']?.toString(),
      record: json['record']?.toString(),
      sportId: json['sport_id']?.toString() ?? json['sportId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'short_name': shortName,
      'logo_url': logoUrl,
      'photo_url': photoUrl,
      'country': country,
      'record': record,
      'sport_id': sportId,
    };
  }
}
