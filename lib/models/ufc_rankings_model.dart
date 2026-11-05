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

  /// Parsea el HTML oficial de UFC (`https://www.ufcespanol.com/rankings` o `https://www.ufc.com/rankings`)
  /// extrayendo todas las divisiones oficiales con su campeón actual y el Top 15 completo.
  factory UfcRankingsModel.fromUfcOfficialHtml(String html) {
    if (html.trim().isEmpty) return UfcRankingsModel.empty();

    var scope = html;
    final metaIdx = scope.indexOf('block-views-blockathlete-rankings-meta-rankings');
    if (metaIdx > 0) {
      scope = scope.substring(0, metaIdx);
    }

    final groupRegex = RegExp(
      r'<div class="view-grouping">([\s\S]*?)</tbody>\s*</table>\s*</div>\s*</div>',
      caseSensitive: false,
    );
    final headerRegex = RegExp(
      r'<div class="view-grouping-header[^>]*>([\s\S]*?)</div>',
      caseSensitive: false,
    );
    final champNameRegex = RegExp(
      r'<h5>\s*<a[^>]*href="([^"]*)"[^>]*>([\s\S]*?)</a>\s*</h5>',
      caseSensitive: false,
    );
    final champImgRegex = RegExp(
      r'<img[^>]*src="([^"]*)"',
      caseSensitive: false,
    );
    final tbodyRegex = RegExp(
      r'<tbody>([\s\S]*?)</tbody>',
      caseSensitive: false,
    );
    final rowRegex = RegExp(
      r'<tr[^>]*>([\s\S]*?)</tr>',
      caseSensitive: false,
    );
    final rankCellRegex = RegExp(
      r'views-field-(?:meta-)?weight-class-rank"[^>]*>([\s\S]*?)</td>',
      caseSensitive: false,
    );
    final titleLinkRegex = RegExp(
      r'views-field-title[^>]*>\s*<a[^>]*href="([^"]*)"[^>]*>([\s\S]*?)</a>',
      caseSensitive: false,
    );
    final changeCellRegex = RegExp(
      r'views-field-(?:meta-)?weight-class-rank-change[^>]*>([\s\S]*?)</td>',
      caseSensitive: false,
    );
    final changeNumRegex = RegExp(r'(\d+)\s*$');

    final categories = <UfcRankingCategoryModel>[];
    final seenIds = <String>{};

    for (final match in groupRegex.allMatches(scope)) {
      final block = match.group(1) ?? '';
      final headerMatch = headerRegex.firstMatch(block);
      if (headerMatch == null) continue;

      final rawHeader = _cleanHtmlText(headerMatch.group(1) ?? '');
      if (rawHeader.isEmpty) continue;

      final meta = _resolveOfficialUfcDivision(rawHeader);
      if (seenIds.contains(meta.id)) continue;

      UfcRankingFighterModel? champion;
      final champMatch = champNameRegex.firstMatch(block);
      if (champMatch != null) {
        final href = champMatch.group(1) ?? '';
        final champName = _cleanHtmlText(champMatch.group(2) ?? '');
        final imgMatch = champImgRegex.firstMatch(block);
        final photoUrl = imgMatch?.group(1)?.trim();
        if (champName.isNotEmpty) {
          champion = UfcRankingFighterModel(
            position: null,
            athleteId: _slugFromHref(href, champName),
            name: champName,
            photoUrl: photoUrl,
          );
        }
      }

      final ranks = <UfcRankingFighterModel>[];
      final tbodyMatch = tbodyRegex.firstMatch(block);
      final rowsScope = tbodyMatch?.group(1) ?? block;
      var fallbackPos = 1;

      for (final rowMatch in rowRegex.allMatches(rowsScope)) {
        final rowHtml = rowMatch.group(1) ?? '';
        final titleMatch = titleLinkRegex.firstMatch(rowHtml);
        if (titleMatch == null) continue;

        final href = titleMatch.group(1) ?? '';
        final fighterName = _cleanHtmlText(titleMatch.group(2) ?? '');
        if (fighterName.isEmpty) continue;

        final rankCell = _cleanHtmlText(rankCellRegex.firstMatch(rowHtml)?.group(1) ?? '');
        final position = int.tryParse(rankCell) ?? fallbackPos;

        String? trend;
        final changeHtml = changeCellRegex.firstMatch(rowHtml)?.group(1) ?? '';
        if (changeHtml.contains('rank-increase')) {
          final numMatch = changeNumRegex.firstMatch(_cleanHtmlText(changeHtml));
          final delta = numMatch?.group(1) ?? '1';
          trend = '+$delta';
        } else if (changeHtml.contains('rank-decrease')) {
          final numMatch = changeNumRegex.firstMatch(_cleanHtmlText(changeHtml));
          final delta = numMatch?.group(1) ?? '1';
          trend = '-$delta';
        } else if (changeHtml.contains('not-ranked')) {
          trend = 'NR';
        }

        ranks.add(
          UfcRankingFighterModel(
            position: position,
            athleteId: _slugFromHref(href, fighterName),
            name: fighterName,
            trend: trend,
          ),
        );
        fallbackPos++;
        if (ranks.length >= 15) break;
      }

      if (ranks.isEmpty) continue;
      seenIds.add(meta.id);

      categories.add(
        UfcRankingCategoryModel(
          id: meta.id,
          name: rawHeader,
          translatedName: meta.translatedName,
          weightLimit: meta.weightLimit,
          gender: meta.gender,
          champion: champion,
          ranks: ranks,
        ),
      );
    }

    return UfcRankingsModel(
      version: 1,
      sport: 'ufc',
      updatedAt: DateTime.now(),
      hasCoverage: categories.isNotEmpty,
      categories: categories,
    );
  }

  /// Snapshot oficial actualizado de UFC Top 15 (15 peleadores por división y campeones vigentes)
  /// utilizado cuando el cliente no puede alcanzar directamente ufc.com (p. ej. CORS en Web)
  /// y el backend remoto devuelve datos antiguos de ESPN.
  factory UfcRankingsModel.officialTop15Fallback() {
    UfcRankingCategoryModel buildCat({
      required String id,
      required String translatedName,
      String? weightLimit,
      required String gender,
      required String championName,
      required List<(int, String, String?)> top15,
    }) {
      return UfcRankingCategoryModel(
        id: id,
        name: translatedName,
        translatedName: translatedName,
        weightLimit: weightLimit,
        gender: gender,
        champion: UfcRankingFighterModel(
          athleteId: _slugFromHref('', championName),
          name: championName,
        ),
        ranks: [
          for (final item in top15)
            UfcRankingFighterModel(
              position: item.$1,
              athleteId: _slugFromHref('', item.$2),
              name: item.$2,
              trend: item.$3,
            ),
        ],
      );
    }

    return UfcRankingsModel(
      version: 1,
      sport: 'ufc',
      updatedAt: DateTime.now(),
      hasCoverage: true,
      categories: [
        buildCat(
          id: 'pound-for-pound',
          translatedName: 'Libra por libra masculino',
          gender: 'MALE',
          championName: 'Islam Makhachev',
          top15: const [
            (1, 'Islam Makhachev', null),
            (2, 'Alexander Volkanovski', null),
            (3, 'Petr Yan', null),
            (4, 'Justin Gaethje', null),
            (5, 'Ilia Topuria', null),
            (6, 'Joshua Van', null),
            (7, 'Sean Strickland', null),
            (8, 'Tom Aspinall', null),
            (9, 'Merab Dvalishvili', null),
            (10, 'Alex Pereira', null),
            (11, 'Ciryl Gane', null),
            (11, 'Khamzat Chimaev', null),
            (13, 'Arman Tsarukyan', null),
            (14, 'Alexandre Pantoja', null),
            (15, 'Carlos Ulberg', null),
          ],
        ),
        buildCat(
          id: 'flyweight',
          translatedName: 'Peso mosca',
          weightLimit: 'Hasta 125 lbs',
          gender: 'MALE',
          championName: 'Joshua Van',
          top15: const [
            (1, 'Alexandre Pantoja', null),
            (2, 'Manel Kape', null),
            (3, 'Brandon Royval', null),
            (4, 'Tatsuro Taira', null),
            (5, 'Kyoji Horiguchi', null),
            (6, 'Lone’er Kavanagh', null),
            (7, 'Asu Almabayev', null),
            (8, 'Brandon Moreno', null),
            (9, 'Amir Albazi', null),
            (10, 'Ramazan Temirov', null),
            (11, 'Tim Elliott', null),
            (12, 'Steve Erceg', null),
            (13, 'Sumudaerji', null),
            (14, 'Tagir Ulanbekov', null),
            (15, 'Alex Perez', null),
          ],
        ),
        buildCat(
          id: 'bantamweight',
          translatedName: 'Peso gallo',
          weightLimit: 'Hasta 135 lbs',
          gender: 'MALE',
          championName: 'Petr Yan',
          top15: const [
            (1, 'Merab Dvalishvili', null),
            (2, "Sean O'Malley", null),
            (3, 'Song Yadong', null),
            (4, 'Umar Nurmagomedov', null),
            (5, 'Mario Bautista', null),
            (6, 'Cory Sandhagen', null),
            (7, 'Payton Talbott', null),
            (8, 'David Martinez', null),
            (9, 'Aiemann Zahabi', null),
            (10, 'Raul Rosas Jr.', null),
            (11, 'Marlon Vera', null),
            (12, 'Deiveson Figueiredo', null),
            (13, 'Marcus McGhee', null),
            (14, 'Raoni Barcelos', null),
            (15, 'Bryce Mitchell', null),
          ],
        ),
        buildCat(
          id: 'featherweight',
          translatedName: 'Peso pluma',
          weightLimit: 'Hasta 145 lbs',
          gender: 'MALE',
          championName: 'Alexander Volkanovski',
          top15: const [
            (1, 'Movsar Evloev', null),
            (2, 'Diego Lopes', null),
            (3, 'Lerone Murphy', null),
            (4, 'Aljamain Sterling', null),
            (5, 'Jean Silva', null),
            (6, 'Yair Rodriguez', null),
            (7, 'Arnold Allen', null),
            (8, 'Youssef Zalal', null),
            (9, 'Kevin Vallejos', null),
            (10, 'Steve Garcia', null),
            (11, 'Aaron Pico', null),
            (12, 'Melquizael Costa', null),
            (13, 'Brian Ortega', null),
            (14, 'Patricio Pitbull', null),
            (15, 'David Onama', null),
          ],
        ),
        buildCat(
          id: 'lightweight',
          translatedName: 'Peso ligero',
          weightLimit: 'Hasta 155 lbs',
          gender: 'MALE',
          championName: 'Justin Gaethje',
          top15: const [
            (1, 'Ilia Topuria', null),
            (2, 'Arman Tsarukyan', null),
            (3, 'Charles Oliveira', null),
            (4, 'Max Holloway', null),
            (5, 'Paddy Pimblett', null),
            (6, 'Benoît Saint Denis', null),
            (7, 'Quillan Salkilld', null),
            (8, 'Mauricio Ruffy', null),
            (9, 'Salahdine Parnasse', null),
            (10, 'Mateusz Gamrot', null),
            (11, 'Rafael Fiziev', null),
            (12, 'Renato Moicano', null),
            (13, 'Tom Nolan', '+1'),
            (14, 'Dan Hooker', '-1'),
            (15, 'Beneil Dariush', 'NR'),
          ],
        ),
        buildCat(
          id: 'welterweight',
          translatedName: 'Peso wélter',
          weightLimit: 'Hasta 170 lbs',
          gender: 'MALE',
          championName: 'Islam Makhachev',
          top15: const [
            (1, 'Ian Machado Garry', null),
            (2, 'Carlos Prates', null),
            (3, 'Michael Morales', null),
            (4, 'Jack Della Maddalena', null),
            (5, 'Gabriel Bonfim', null),
            (6, 'Sean Brady', null),
            (7, 'Belal Muhammad', null),
            (8, 'Leon Edwards', null),
            (9, 'Mike Malott', null),
            (9, 'Kamaru Usman', null),
            (11, 'Yaroslav Amosov', null),
            (12, 'Uroš Medić', null),
            (13, 'Joaquin Buckley', null),
            (14, 'Daniel Rodriguez', null),
            (15, 'Kevin Holland', null),
          ],
        ),
        buildCat(
          id: 'middleweight',
          translatedName: 'Peso medio',
          weightLimit: 'Hasta 185 lbs',
          gender: 'MALE',
          championName: 'Sean Strickland',
          top15: const [
            (1, 'Khamzat Chimaev', null),
            (2, 'Dricus Du Plessis', null),
            (3, 'Nassourdine Imavov', null),
            (4, 'Brendan Allen', null),
            (5, 'Caio Borralho', null),
            (6, 'Joe Pyfer', null),
            (7, 'Gregory Rodrigues', null),
            (8, 'Anthony Hernandez', null),
            (9, 'Israel Adesanya', null),
            (10, 'Christian Leroy Duncan', null),
            (11, 'Abus Magomedov', null),
            (12, 'Jared Cannonier', null),
            (13, 'Ikram Aliskerov', null),
            (14, 'Bo Nickal', null),
            (15, 'Shara Magomedov', null),
          ],
        ),
        buildCat(
          id: 'light-heavyweight',
          translatedName: 'Peso semipesado',
          weightLimit: 'Hasta 205 lbs',
          gender: 'MALE',
          championName: 'Carlos Ulberg',
          top15: const [
            (1, 'Magomed Ankalaev', null),
            (2, 'Jiří Procházka', null),
            (3, 'Alex Pereira', null),
            (4, 'Khalil Rountree Jr.', null),
            (5, 'Navajo Stirling', null),
            (6, 'Paulo Costa', null),
            (7, 'Dominick Reyes', null),
            (8, 'Bogdan Guskov', null),
            (9, 'Jan Błachowicz', null),
            (10, 'Azamat Murzakanov', null),
            (11, 'Robert Whittaker', null),
            (12, 'Abdul Rakhman Yakhyaev', null),
            (13, 'Alonzo Menifield', null),
            (14, 'Reinier de Ridder', null),
            (15, 'Nikita Krylov', null),
          ],
        ),
        buildCat(
          id: 'heavyweight',
          translatedName: 'Peso pesado',
          weightLimit: 'Hasta 265 lbs',
          gender: 'MALE',
          championName: 'Ciryl Gane',
          top15: const [
            (1, 'Tom Aspinall', null),
            (2, 'Alexander Volkov', null),
            (3, 'Sergei Pavlovich', null),
            (4, 'Josh Hokit', null),
            (5, 'Curtis Blaydes', null),
            (6, 'Waldo Cortes Acosta', null),
            (7, 'Rizvan Kuniev', null),
            (8, 'Vitor Petrino', null),
            (9, 'Serghei Spivac', null),
            (10, 'Ante Delija', null),
            (11, 'Valter Walker', null),
            (12, 'Derrick Lewis', null),
            (12, 'Tyrell Fortune', null),
            (14, 'Aleksandar Rakić', null),
            (15, 'Mario Pinto', null),
          ],
        ),
        buildCat(
          id: 'womens-pound-for-pound',
          translatedName: 'Libra por libra femenino',
          gender: 'FEMALE',
          championName: 'Valentina Shevchenko',
          top15: const [
            (1, 'Valentina Shevchenko', null),
            (2, 'Kayla Harrison', null),
            (3, 'Zhang Weili', null),
            (4, 'Natalia Silva', null),
            (5, 'Mackenzie Dern', null),
            (6, 'Alexa Grasso', null),
            (7, 'Manon Fiorot', null),
            (8, 'Tatiana Suarez', null),
            (9, 'Jasmine Jasudavicius', null),
            (10, 'Erin Blanchfield', null),
            (11, 'Julianna Peña', null),
            (12, 'Virna Jandiroba', null),
            (13, 'Rose Namajunas', null),
            (14, 'Raquel Pennington', null),
            (15, 'Denise Gomes', null),
          ],
        ),
        buildCat(
          id: 'womens-strawweight',
          translatedName: 'Peso paja femenino',
          weightLimit: 'Hasta 115 lbs',
          gender: 'FEMALE',
          championName: 'Mackenzie Dern',
          top15: const [
            (1, 'Zhang Weili', null),
            (2, 'Tatiana Suarez', null),
            (3, 'Virna Jandiroba', null),
            (4, 'Denise Gomes', null),
            (5, 'Gillian Robertson', null),
            (6, 'Yan Xiaonan', null),
            (7, 'Fatima Kline', null),
            (8, 'Loopy Godinez', null),
            (9, 'Alexia Thainara', null),
            (10, 'Tabatha Ricci', '+1'),
            (11, 'Jéssica Andrade', '-1'),
            (12, 'Amanda Lemos', null),
            (13, 'Amanda Ribas', null),
            (14, 'Angela Hill', null),
            (15, 'Mizuki', null),
          ],
        ),
        buildCat(
          id: 'womens-flyweight',
          translatedName: 'Peso mosca femenino',
          weightLimit: 'Hasta 125 lbs',
          gender: 'FEMALE',
          championName: 'Natalia Silva',
          top15: const [
            (1, 'Valentina Shevchenko', null),
            (2, 'Alexa Grasso', null),
            (3, 'Manon Fiorot', null),
            (4, 'Jasmine Jasudavicius', null),
            (5, 'Erin Blanchfield', null),
            (6, 'Rose Namajunas', null),
            (7, 'Maycee Barber', null),
            (8, 'Wang Cong', null),
            (9, 'Tracy Cortez', null),
            (10, 'Miranda Maverick', null),
            (11, 'Karine Silva', null),
            (12, "Casey O'Neill", null),
            (13, 'Eduarda Moura', null),
            (14, 'Regina Tarin', '+1'),
            (15, 'Gabriella Fernandes', '-1'),
          ],
        ),
        buildCat(
          id: 'womens-bantamweight',
          translatedName: 'Peso gallo femenino',
          weightLimit: 'Hasta 135 lbs',
          gender: 'FEMALE',
          championName: 'Kayla Harrison',
          top15: const [
            (1, 'Julianna Peña', null),
            (2, 'Joselyne Edwards', null),
            (3, 'Ailin Perez', null),
            (4, 'Norma Dumont', null),
            (5, 'Luana Santos', '+2'),
            (5, 'Raquel Pennington', null),
            (7, 'Yana Santos', '-1'),
            (8, 'Jacqueline Cavalcanti', null),
            (9, 'Macy Chiasson', null),
            (10, 'Karol Rosa', null),
            (11, 'Bia Mesquita', null),
            (12, 'Michelle Montague', null),
            (13, 'Nora Cornolle', null),
            (14, 'Chelsea Chandler', null),
            (15, 'Alice Pereira', null),
          ],
        ),
      ],
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

  static String _cleanHtmlText(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&#039;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _slugFromHref(String href, String fallbackName) {
    final match = RegExp(r'/athlete/([a-zA-Z0-9_-]+)').firstMatch(href);
    if (match != null && match.group(1) != null) {
      return match.group(1)!.toLowerCase();
    }
    return fallbackName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static ({
    String id,
    String translatedName,
    String? weightLimit,
    String gender,
  }) _resolveOfficialUfcDivision(String rawHeader) {
    final lower = rawHeader.toLowerCase();

    if (lower.contains("women's pound-for-pound") ||
        lower.contains("women's pound for pound") ||
        lower.contains('libra por libra femenino')) {
      return (
        id: 'womens-pound-for-pound',
        translatedName: 'Libra por libra femenino',
        weightLimit: null,
        gender: 'FEMALE',
      );
    }
    if (lower.contains("men's pound-for-pound") ||
        lower.contains("men's pound for pound") ||
        lower.contains('pound-for-pound') ||
        lower.contains('libra por libra')) {
      return (
        id: 'pound-for-pound',
        translatedName: 'Libra por libra masculino',
        weightLimit: null,
        gender: 'MALE',
      );
    }
    if (lower.contains('peso de la mujer') ||
        lower.contains("women's strawweight") ||
        lower.contains('paja femenino')) {
      return (
        id: 'womens-strawweight',
        translatedName: 'Peso paja femenino',
        weightLimit: 'Hasta 115 lbs',
        gender: 'FEMALE',
      );
    }
    if (lower.contains("women's flyweight") ||
        lower.contains('mosca de las mujeres') ||
        lower.contains('mosca femenino')) {
      return (
        id: 'womens-flyweight',
        translatedName: 'Peso mosca femenino',
        weightLimit: 'Hasta 125 lbs',
        gender: 'FEMALE',
      );
    }
    if (lower.contains('gallo de las mujeres') ||
        lower.contains("women's bantamweight") ||
        lower.contains('gallo femenino')) {
      return (
        id: 'womens-bantamweight',
        translatedName: 'Peso gallo femenino',
        weightLimit: 'Hasta 135 lbs',
        gender: 'FEMALE',
      );
    }
    if (lower.contains('pluma de las mujeres') ||
        lower.contains("women's featherweight") ||
        lower.contains('pluma femenino')) {
      return (
        id: 'womens-featherweight',
        translatedName: 'Peso pluma femenino',
        weightLimit: 'Hasta 145 lbs',
        gender: 'FEMALE',
      );
    }
    if (lower.contains('semipesado') || lower.contains('light heavyweight')) {
      return (
        id: 'light-heavyweight',
        translatedName: 'Peso semipesado',
        weightLimit: 'Hasta 205 lbs',
        gender: 'MALE',
      );
    }
    if (lower.contains('pesado') || lower.contains('heavyweight')) {
      return (
        id: 'heavyweight',
        translatedName: 'Peso pesado',
        weightLimit: 'Hasta 265 lbs',
        gender: 'MALE',
      );
    }
    if (lower.contains('medio') || lower.contains('middleweight')) {
      return (
        id: 'middleweight',
        translatedName: 'Peso medio',
        weightLimit: 'Hasta 185 lbs',
        gender: 'MALE',
      );
    }
    if (lower.contains('welter') || lower.contains('wélter')) {
      return (
        id: 'welterweight',
        translatedName: 'Peso wélter',
        weightLimit: 'Hasta 170 lbs',
        gender: 'MALE',
      );
    }
    if (lower.contains('ligero') || lower.contains('lightweight')) {
      return (
        id: 'lightweight',
        translatedName: 'Peso ligero',
        weightLimit: 'Hasta 155 lbs',
        gender: 'MALE',
      );
    }
    if (lower.contains('pluma') || lower.contains('featherweight')) {
      return (
        id: 'featherweight',
        translatedName: 'Peso pluma',
        weightLimit: 'Hasta 145 lbs',
        gender: 'MALE',
      );
    }
    if (lower.contains('gallo') || lower.contains('bantamweight')) {
      return (
        id: 'bantamweight',
        translatedName: 'Peso gallo',
        weightLimit: 'Hasta 135 lbs',
        gender: 'MALE',
      );
    }
    if (lower.contains('mosca') || lower.contains('flyweight')) {
      return (
        id: 'flyweight',
        translatedName: 'Peso mosca',
        weightLimit: 'Hasta 125 lbs',
        gender: 'MALE',
      );
    }

    return (
      id: _slugFromHref('', rawHeader),
      translatedName: rawHeader,
      weightLimit: null,
      gender: 'MALE',
    );
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
