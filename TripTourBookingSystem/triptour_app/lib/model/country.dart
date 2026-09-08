import 'package:flutter/foundation.dart';

class Country {
  final int countryId;
  final String countryNameTH;
  final String countryNameEn;
  final String continent;
  bool isSelected;

  Country({
    required this.countryId,
    required this.countryNameTH,
    required this.countryNameEn,
    required this.continent,
    this.isSelected = false,
  });
  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      countryId: json['country_id'],
      countryNameTH: json['country_name_th'],
      countryNameEn: json['country_name_en'],
      continent: json['continent'],
    );
  }
  @override
  String toString() {
    return countryNameTH;
  }
}
