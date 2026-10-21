class FighterModel {
  final String id;
  final String name;
  final String? nickname;
  final String? photoUrl;
  final String? record;
  final String? weightClass;
  final String? country;

  const FighterModel({
    required this.id,
    required this.name,
    this.nickname,
    this.photoUrl,
    this.record,  
    this.weightClass,
    this.country,
  });

  factory FighterModel.fromJson(Map<String, dynamic> json) {
    return FighterModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Peleador Desconocido',
      nickname: json['nickname']?.toString(),
      photoUrl: json['photo_url']?.toString() ??
          json['photoUrl']?.toString() ??
          json['logo_url']?.toString() ??
          json['logoUrl']?.toString(),
      record: json['record']?.toString(),
      weightClass: json['weight_class']?.toString() ?? json['weightClass']?.toString(),
      country: json['country']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nickname': nickname,
      'photo_url': photoUrl,
      'record': record,
      'weight_class': weightClass,
      'country': country,
    };
  }
}
