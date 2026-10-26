/// Modelo de contrato y dominio para los rankings oficiales de UFC (v1).
class UfcRankingsModel {
  final int version;
  final String sport;
  final DateTime? updatedAt;
  final bool hasCoverage;
  final List<UfcRankingCategoryModel> categories;

  const UfcRankingsModel({
    this.version = 1,
    this.sport = 'ufc',
    this.updatedAt,
    this.hasCoverage = true,
    this.categories = const [],
  });

  factory UfcRankingsModel.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categories'];
    final categoriesList = <UfcRankingCategoryModel>[];
    if (rawCats is List) {
      for (final c in rawCats) {
        if (c is Map<String, dynamic>) {
          categoriesList.add(UfcRankingCategoryModel.fromJson(c));
        }
      }
    }

    DateTime? parsedDate;
    final rawDate = json['updatedAt'] ?? json['updated_at'];
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString());
    }

    return UfcRankingsModel(
      version: json['version'] is int
          ? json['version'] as int
          : (int.tryParse(json['version']?.toString() ?? '1') ?? 1),
      sport: json['sport']?.toString() ?? 'ufc',
      updatedAt: parsedDate,
      hasCoverage: json['hasCoverage'] == true ||
          (json['hasCoverage'] == null && categoriesList.isNotEmpty),
      categories: categoriesList,
    );
  }

  factory UfcRankingsModel.empty({
    String? message,
    bool hasCoverage = false,
  }) {
    return UfcRankingsModel(
      version: 1,
      sport: 'ufc',
      updatedAt: DateTime.now(),
      hasCoverage: hasCoverage,
      categories: const [],
    );
  }

  /// Parser resiliente para la respuesta cruda directa de ESPN
  /// (fallback cliente directo ante indisponibilidad del backend).
  factory UfcRankingsModel.fromEspnRaw(Map<String, dynamic> json) {
    final rawRankings = json['rankings'];
    if (rawRankings is! List || rawRankings.isEmpty) {
      return UfcRankingsModel.empty();
    }

    final championCats = <Map<String, dynamic>>[];
    final contenderCats = <Map<String, dynamic>>[];

    for (final r in rawRankings) {
      if (r is Map<String, dynamic>) {
        final type = r['type']?.toString().toLowerCase() ?? '';
        if (type.endsWith('-champions')) {
          championCats.add(r);
        } else {
          contenderCats.add(r);
        }
      }
    }

    final categories = <UfcRankingCategoryModel>[];

    for (final cat in contenderCats) {
      final catType = cat['type']?.toString() ?? cat['id']?.toString() ?? '';
      final rawName = cat['name']?.toString() ?? catType;
      final translation = _translateDivision(rawName, catType);

      // Buscar campeón de la división correspondiente
      Map<String, dynamic>? matchingChampCat;
      for (final ch in championCats) {
        final chType = ch['type']?.toString() ?? '';
        if (chType == '$catType-champions') {
          matchingChampCat = ch;
          break;
        }
        final chSlug = ch['weightClass'] is Map
            ? (ch['weightClass'] as Map)['slug']?.toString()
            : null;
        final catSlug = cat['weightClass'] is Map
            ? (cat['weightClass'] as Map)['slug']?.toString()
            : null;
        if (chSlug != null && catSlug != null && chSlug == catSlug) {
          matchingChampCat = ch;
          break;
        }
      }

      UfcRankingFighterModel? champion;
      if (matchingChampCat != null && matchingChampCat['ranks'] is List) {
        final chRanks = matchingChampCat['ranks'] as List;
        if (chRanks.isNotEmpty && chRanks.first is Map<String, dynamic>) {
          champion = _mapFighter(chRanks.first as Map<String, dynamic>, isChampion: true);
        }
      }

      final ranksList = <UfcRankingFighterModel>[];
      if (cat['ranks'] is List) {
        for (final r in cat['ranks'] as List) {
          if (r is Map<String, dynamic>) {
            final f = _mapFighter(r, isChampion: false);
            if (f != null) ranksList.add(f);
          }
        }
      }

      ranksList.sort((a, b) => (a.position ?? 999).compareTo(b.position ?? 999));

      categories.add(
        UfcRankingCategoryModel(
          id: catType,
          name: rawName,
          translatedName: translation.translatedName,
          weightLimit: translation.weightLimit,
          gender: cat['gender']?.toString() ??
              (catType.contains('women') ? 'FEMALE' : 'MALE'),
          champion: champion,
          ranks: ranksList,
        ),
      );
    }

    // Orden jerárquico estándar
    const order = [
      'pound-for-pound',
      'womens-pound-for-pound',
      'heavyweight',
      'light-heavyweight',
      'middleweight',
      'welterweight',
      'lightweight',
      'featherweight',
      'bantamweight',
      'flyweight',
      'womens-featherweight',
      'womens-bantamweight',
      'womens-flyweight',
      'womens-strawweight',
    ];

    categories.sort((a, b) {
      final idxA = order.indexOf(a.id);
      final idxB = order.indexOf(b.id);
      if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
      if (idxA != -1) return -1;
      if (idxB != -1) return 1;
      return a.name.compareTo(b.name);
    });

    return UfcRankingsModel(
      version: 1,
      sport: 'ufc',
      updatedAt: DateTime.now(),
      hasCoverage: categories.isNotEmpty,
      categories: categories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'sport': sport,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'hasCoverage': hasCoverage,
      'categories': categories.map((c) => c.toJson()).toList(),
    };
  }

  static UfcRankingFighterModel? _mapFighter(
    Map<String, dynamic> r, {
    required bool isChampion,
  }) {
    final athlete = r['athlete'];
    if (athlete is! Map<String, dynamic>) return null;

    final athleteId = athlete['id']?.toString() ?? '';
    final name = athlete['displayName']?.toString() ??
        athlete['name']?.toString() ??
        'Peleador';
    final nickname = athlete['nickname']?.toString();
    final photoUrl = athlete['headshot'] is Map
        ? (athlete['headshot'] as Map)['href']?.toString()
        : (athlete['flag'] is Map
            ? (athlete['flag'] as Map)['href']?.toString()
            : null);
    final flagUrl = athlete['flag'] is Map
        ? (athlete['flag'] as Map)['href']?.toString()
        : null;
    final country = athlete['citizenshipCountry']?.toString();
    final defenses = r['defenses'] is int
        ? r['defenses'] as int
        : int.tryParse(r['defenses']?.toString() ?? '');
    final trend = r['trend']?.toString();
    final record = r['recordSummary']?.toString() ?? r['record']?.toString();

    final position = isChampion
        ? null
        : (r['current'] is int
            ? r['current'] as int
            : int.tryParse(r['current']?.toString() ?? ''));

    return UfcRankingFighterModel(
      position: position,
      athleteId: athleteId,
      name: name,
      nickname: nickname,
      record: record,
      photoUrl: photoUrl,
      flagUrl: flagUrl,
      country: country,
      defenses: defenses,
      trend: trend,
    );
  }

  static ({String translatedName, String? weightLimit}) _translateDivision(
    String rawName,
    String type,
  ) {
    final lower = rawName.toLowerCase();
    final t = type.toLowerCase();

    if (lower.contains("women's strawweight") ||
        t == 'womens-strawweight' ||
        t == 'womens-strawweight-champions') {
      return (translatedName: 'Peso paja femenino', weightLimit: 'Hasta 115 lbs');
    }
    if (lower.contains("women's flyweight") ||
        t == 'womens-flyweight' ||
        t == 'womens-flyweight-champions') {
      return (translatedName: 'Peso mosca femenino', weightLimit: 'Hasta 125 lbs');
    }
    if (lower.contains("women's bantamweight") ||
        t == 'womens-bantamweight' ||
        t == 'womens-bantamweight-champions') {
      return (translatedName: 'Peso gallo femenino', weightLimit: 'Hasta 135 lbs');
    }
    if (lower.contains("women's featherweight") ||
        t == 'womens-featherweight' ||
        t == 'womens-featherweight-champions') {
      return (translatedName: 'Peso pluma femenino', weightLimit: 'Hasta 145 lbs');
    }
    if (lower.contains("women's pound for pound") ||
        t == 'womens-pound-for-pound') {
      return (translatedName: 'Libra por libra femenino', weightLimit: null);
    }
    if (lower.contains("men's pound for pound") ||
        lower.contains('pound for pound') ||
        t == 'pound-for-pound') {
      return (translatedName: 'Libra por libra masculino', weightLimit: null);
    }
    if (lower.contains('heavyweight') && !lower.contains('light heavyweight')) {
      return (translatedName: 'Peso pesado', weightLimit: 'Hasta 265 lbs');
    }
    if (lower.contains('light heavyweight') ||
        t == 'light-heavyweight' ||
        t == 'light-heavyweight-champions') {
      return (translatedName: 'Peso semipesado', weightLimit: 'Hasta 205 lbs');
    }
    if (lower.contains('middleweight') ||
        t == 'middleweight' ||
        t == 'middleweight-champions') {
      return (translatedName: 'Peso medio', weightLimit: 'Hasta 185 lbs');
    }
    if (lower.contains('welterweight') ||
        t == 'welterweight' ||
        t == 'welterweight-champions') {
      return (translatedName: 'Peso wélter', weightLimit: 'Hasta 170 lbs');
    }
    if (lower.contains('lightweight') ||
        t == 'lightweight' ||
        t == 'lightweight-champions') {
      return (translatedName: 'Peso ligero', weightLimit: 'Hasta 155 lbs');
    }
    if (lower.contains('featherweight') ||
        t == 'featherweight' ||
        t == 'featherweight-champions') {
      return (translatedName: 'Peso pluma', weightLimit: 'Hasta 145 lbs');
    }
    if (lower.contains('bantamweight') ||
        t == 'bantamweight' ||
        t == 'bantamweight-champions') {
      return (translatedName: 'Peso gallo', weightLimit: 'Hasta 135 lbs');
    }
    if (lower.contains('flyweight') ||
        t == 'flyweight' ||
        t == 'flyweight-champions') {
      return (translatedName: 'Peso mosca', weightLimit: 'Hasta 125 lbs');
    }
    if (lower.contains('strawweight') || t == 'strawweight') {
      return (translatedName: 'Peso paja', weightLimit: 'Hasta 115 lbs');
    }
    return (translatedName: rawName, weightLimit: null);
  }
}

/// Categoría o división de peso de UFC (ej. Peso Pesado, Libra por Libra).
class UfcRankingCategoryModel {
  final String id;
  final String name;
  final String translatedName;
  final String? weightLimit;
  final String? gender;
  final UfcRankingFighterModel? champion;
  final List<UfcRankingFighterModel> ranks;

  const UfcRankingCategoryModel({
    required this.id,
    required this.name,
    required this.translatedName,
    this.weightLimit,
    this.gender,
    this.champion,
    this.ranks = const [],
  });

  bool get hasChampion => champion != null;

  factory UfcRankingCategoryModel.fromJson(Map<String, dynamic> json) {
    final ranksList = <UfcRankingFighterModel>[];
    if (json['ranks'] is List) {
      for (final r in json['ranks'] as List) {
        if (r is Map<String, dynamic>) {
          ranksList.add(UfcRankingFighterModel.fromJson(r));
        }
      }
    }

    return UfcRankingCategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      translatedName: json['translatedName']?.toString() ??
          json['translated_name']?.toString() ??
          json['name']?.toString() ??
          '',
      weightLimit: json['weightLimit']?.toString() ??
          json['weight_limit']?.toString(),
      gender: json['gender']?.toString(),
      champion: json['champion'] is Map<String, dynamic>
          ? UfcRankingFighterModel.fromJson(
              json['champion'] as Map<String, dynamic>)
          : null,
      ranks: ranksList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'translatedName': translatedName,
      if (weightLimit != null) 'weightLimit': weightLimit,
      if (gender != null) 'gender': gender,
      if (champion != null) 'champion': champion!.toJson(),
      'ranks': ranks.map((r) => r.toJson()).toList(),
    };
  }
}

/// Peleador rankeado o campeón oficial de una división de UFC.
class UfcRankingFighterModel {
  final int? position;
  final String athleteId;
  final String? participantId;
  final String name;
  final String? nickname;
  final String? record;
  final String? photoUrl;
  final String? flagUrl;
  final String? country;
  final int? defenses;
  final String? trend;

  const UfcRankingFighterModel({
    this.position,
    required this.athleteId,
    this.participantId,
    required this.name,
    this.nickname,
    this.record,
    this.photoUrl,
    this.flagUrl,
    this.country,
    this.defenses,
    this.trend,
  });

  bool get isChampion => position == null || position == 0;

  String get displayName =>
      nickname != null && nickname!.trim().isNotEmpty
          ? '$name "$nickname"'
          : name;

  factory UfcRankingFighterModel.fromJson(Map<String, dynamic> json) {
    return UfcRankingFighterModel(
      position: json['position'] is int
          ? json['position'] as int
          : int.tryParse(json['position']?.toString() ?? ''),
      athleteId: json['athleteId']?.toString() ??
          json['athlete_id']?.toString() ??
          '',
      participantId: json['participantId']?.toString() ??
          json['participant_id']?.toString(),
      name: json['name']?.toString() ?? 'Peleador',
      nickname: json['nickname']?.toString(),
      record: json['record']?.toString(),
      photoUrl: json['photoUrl']?.toString() ?? json['photo_url']?.toString(),
      flagUrl: json['flagUrl']?.toString() ?? json['flag_url']?.toString(),
      country: json['country']?.toString(),
      defenses: json['defenses'] is int
          ? json['defenses'] as int
          : int.tryParse(json['defenses']?.toString() ?? ''),
      trend: json['trend']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (position != null) 'position': position,
      'athleteId': athleteId,
      if (participantId != null) 'participantId': participantId,
      'name': name,
      if (nickname != null) 'nickname': nickname,
      if (record != null) 'record': record,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (flagUrl != null) 'flagUrl': flagUrl,
      if (country != null) 'country': country,
      if (defenses != null) 'defenses': defenses,
      if (trend != null) 'trend': trend,
    };
  }
}
