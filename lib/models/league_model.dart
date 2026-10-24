class LeagueModel {
  final String id;
  final String name;
  final String slug;
  final String? country;
  final String? logoUrl;
  final int tier;
  final bool isActive;
  final String? sportId;

  const LeagueModel({
    required this.id,
    required this.name,
    required this.slug,
    this.country,
    this.logoUrl,
    this.tier = 1,
    this.isActive = true,
    this.sportId,
  });

  bool get isTier1 => tier == 1;

  factory LeagueModel.fromJson(Map<String, dynamic> json) {
    return LeagueModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      country: json['country']?.toString(),
      logoUrl: json['logoUrl']?.toString() ??
          json['logo_url']?.toString() ??
          json['logo']?.toString(),
      tier: json['tier'] is int
          ? json['tier'] as int
          : int.tryParse(json['tier']?.toString() ?? '1') ?? 1,
      isActive: json['is_active'] == true || json['isActive'] == true,
      sportId: json['sport_id']?.toString() ?? json['sportId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'country': country,
      'logo_url': logoUrl,
      'tier': tier,
      'is_active': isActive,
      'sport_id': sportId,
    };
  }
}
