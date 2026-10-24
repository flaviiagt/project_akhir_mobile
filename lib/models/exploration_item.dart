import 'package:flutter/material.dart';

class CampusTag {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;

  const CampusTag({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });
}

class CampusItem {
  final String id;
  final String name;
  final String location;
  final String country;
  final String countryCode; // GB, NL, AU, etc.
  final String qsRank;
  final String description;
  final List<CampusTag> tags;
  final String tuition;
  final String imageUrl;
  final String popularMajor;
  final double latitude;
  final double longitude;
  final bool isBookmarked;
  final bool isComparing;

  const CampusItem({
    required this.id,
    required this.name,
    required this.location,
    required this.country,
    required this.countryCode,
    required this.qsRank,
    required this.description,
    required this.tags,
    required this.tuition,
    required this.imageUrl,
    required this.popularMajor,
    this.latitude = 55.9445,
    this.longitude = -3.1892,
    this.isBookmarked = false,
    this.isComparing = false,
  });

  CampusItem copyWith({
    double? latitude,
    double? longitude,
    bool? isBookmarked,
    bool? isComparing,
  }) {
    return CampusItem(
      id: id,
      name: name,
      location: location,
      country: country,
      countryCode: countryCode,
      qsRank: qsRank,
      description: description,
      tags: tags,
      tuition: tuition,
      imageUrl: imageUrl,
      popularMajor: popularMajor,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isComparing: isComparing ?? this.isComparing,
    );
  }
}

class CityItem {
  final String id;
  final String name;
  final String emoji;
  final String region;
  final String tag;
  final String description;
  final String weather;
  final String weatherTip;
  final String ppiCommunity;
  final String ppiCount;
  final String livingCost;
  final String livingCostIdr;
  final String lpdpStandard;
  final String imageUrl;
  final bool isFavorite;

  const CityItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.region,
    required this.tag,
    required this.description,
    required this.weather,
    required this.weatherTip,
    required this.ppiCommunity,
    required this.ppiCount,
    required this.livingCost,
    required this.livingCostIdr,
    required this.lpdpStandard,
    required this.imageUrl,
    this.isFavorite = false,
  });

  CityItem copyWith({
    String? weather,
    String? weatherTip,
    bool? isFavorite,
  }) {
    return CityItem(
      id: id,
      name: name,
      emoji: emoji,
      region: region,
      tag: tag,
      description: description,
      weather: weather ?? this.weather,
      weatherTip: weatherTip ?? this.weatherTip,
      ppiCommunity: ppiCommunity,
      ppiCount: ppiCount,
      livingCost: livingCost,
      livingCostIdr: livingCostIdr,
      lpdpStandard: lpdpStandard,
      imageUrl: imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
