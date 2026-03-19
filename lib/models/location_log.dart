import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

class LocationLog {
  const LocationLog({
    required this.id,
    required this.groupId,
    required this.longitude,
    required this.latitude,
    required this.accuracy,
    required this.altitude,
    required this.altitudeAccuracy,
    required this.heading,
    required this.headingAccuracy,
    required this.speed,
    required this.speedAccuracy,
    required this.createdAt,
  });

  factory LocationLog.fromPosition(Position position, String groupId) {
    return LocationLog(
      id: const Uuid().v4(),
      groupId: groupId,
      longitude: position.longitude,
      latitude: position.latitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      altitudeAccuracy: position.altitudeAccuracy,
      heading: position.heading,
      headingAccuracy: position.headingAccuracy,
      speed: position.speed,
      speedAccuracy: position.speedAccuracy,
      createdAt: position.timestamp,
    );
  }

  final String id;
  final String groupId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double altitudeAccuracy;
  final double heading;
  final double headingAccuracy;
  final double speed;
  final double speedAccuracy;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'altitudeAccuracy': altitudeAccuracy,
      'heading': heading,
      'headingAccuracy': headingAccuracy,
      'speed': speed,
      'speedAccuracy': speedAccuracy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
