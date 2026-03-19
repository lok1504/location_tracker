part 'background_location_model.g.dart';

class BackgroundLocationModel {
  BackgroundLocationModel({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.bearing,
    this.timestamp,
    this.provider,
  });

  factory BackgroundLocationModel.fromJson(Map<String, dynamic> json) =>
      _$BackgroundLocationModelFromJson(json);

  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? bearing;
  final int? timestamp;
  final String? provider;

  DateTime? get dateTime => timestamp != null
      ? DateTime.fromMillisecondsSinceEpoch(timestamp!)
      : null;

  Map<String, dynamic> toJson() => _$BackgroundLocationModelToJson(this);
}
