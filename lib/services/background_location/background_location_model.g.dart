// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_location_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BackgroundLocationModel _$BackgroundLocationModelFromJson(
  Map<String, dynamic> json,
) => BackgroundLocationModel(
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  accuracy: (json['accuracy'] as num?)?.toDouble(),
  altitude: (json['altitude'] as num?)?.toDouble(),
  speed: (json['speed'] as num?)?.toDouble(),
  bearing: (json['bearing'] as num?)?.toDouble(),
  timestamp: (json['timestamp'] as num?)?.toInt(),
  provider: json['provider'] as String?,
);

Map<String, dynamic> _$BackgroundLocationModelToJson(
  BackgroundLocationModel instance,
) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'accuracy': instance.accuracy,
  'altitude': instance.altitude,
  'speed': instance.speed,
  'bearing': instance.bearing,
  'timestamp': instance.timestamp,
  'provider': instance.provider,
};
