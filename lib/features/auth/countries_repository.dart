import 'dart:convert';

import '../../core/api_client.dart';
import '../../models/auth_user.dart';

/// Représentation d'un pays pour le sélecteur d'inscription.
class Country {
  final int id;
  final String libelle;
  final String prefix;
  final String timeZone;
  final int decalageHoraire;

  Country({
    required this.id,
    required this.libelle,
    required this.prefix,
    required this.timeZone,
    required this.decalageHoraire,
  });

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        id: json["id"] as int,
        libelle: json["libelle"] as String,
        prefix: json["prefix"] as String,
        timeZone: json["timeZone"] as String,
        decalageHoraire: json["decalageHoraire"] as int,
      );
}

class CountryRepository {
  CountryRepository(this._api);
  final ApiClient _api;

  Future<List<Country>> fetchCountries() async {
    final data = await _api.get("/api/countries");
    final raw = data["countries"] as List?;
    if (raw == null) return [];
    return raw
        .map((c) => Country.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}
