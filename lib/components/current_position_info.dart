import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class CurrentPositionInfo extends StatelessWidget {
  const CurrentPositionInfo({required this.currentPosition, super.key});

  final Position currentPosition;

  @override
  Widget build(BuildContext context) {
    final timestamp = DateFormat(
      'y-MM-dd HH:mm:ss',
    ).format(currentPosition.timestamp.toLocal());

    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        spacing: 5,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(
            context,
            'Coordinates:',
            '${currentPosition.latitude.toStringAsFixed(6)}, '
                '${currentPosition.longitude.toStringAsFixed(6)}',
          ),
          _infoRow(
            context,
            'Accuracy:',
            '${currentPosition.accuracy.toStringAsFixed(2)} m',
          ),
          _infoRow(
            context,
            'Altitude:',
            '${currentPosition.altitude.toStringAsFixed(2)} m',
          ),
          _infoRow(
            context,
            'Speed:',
            '${currentPosition.speed.toStringAsFixed(2)} m/s',
          ),
          _infoRow(
            context,
            'Heading:',
            '${currentPosition.heading.toStringAsFixed(2)}°',
          ),
          _infoRow(context, 'Timestamp:', timestamp),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
