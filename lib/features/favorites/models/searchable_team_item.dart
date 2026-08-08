import '../../../models/sport_type.dart';

class SearchableTeamItem {
  final String id;
  final String name;
  final String? shortName;
  final String? logoUrl;
  final String? photoUrl;
  final SportType sport;
  final String league;
  final String? country;
  final String? record;
  final bool isCombat;

  const SearchableTeamItem({
    required this.id,
    required this.name,
    this.shortName,
    this.logoUrl,
    this.photoUrl,
    required this.sport,
    required this.league,
    this.country,
    this.record,
    this.isCombat = false,
  });

  String get displayName => shortName ?? name;

  SearchableTeamItem copyWith({
    String? id,
    String? name,
    String? shortName,
    String? logoUrl,
    String? photoUrl,
    SportType? sport,
    String? league,
    String? country,
    String? record,
    bool? isCombat,
  }) {
    return SearchableTeamItem(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      logoUrl: logoUrl ?? this.logoUrl,
      photoUrl: photoUrl ?? this.photoUrl,
      sport: sport ?? this.sport,
      league: league ?? this.league,
      country: country ?? this.country,
      record: record ?? this.record,
      isCombat: isCombat ?? this.isCombat,
    );
  }
}
