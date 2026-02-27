library;

import "reading.dart";

/// Represents the history associated with a device.
///
/// This is a snapshot of the history, at the time of the query. There's no
/// guarantee how long this information will remain accurate.

class DeviceHistory {
  /// Indicates how many data points were in the device's history at the time
  /// of the query.
  final int totalPoints;

  /// If not `null`, contains a pair of the oldest and newest reading,
  /// respectively, at the time of the query. It is possible that, after
  /// this query returns, the oldest point is dropped due to new points being
  /// added.
  final (Reading, Reading) summary;

  const DeviceHistory._({required this.totalPoints, required this.summary});

  /// Creates a [DeviceHistory] from a JSON map returned by the API.
  ///
  /// Returns `null` if the JSON is invalid or if the device has no history
  /// (i.e., `totalPoints` is not greater than zero).
  static DeviceHistory? fromJson(Map<String, dynamic>? json) =>
      switch (json) {
        {
          'totalPoints': int totalPoints,
          'firstPoint': {
            'stamp': DateTime fStamp,
            'boolValue': bool? fBool,
            'intValue': int? fInt,
            'floatValue': double? fFlt,
            'stringValue': String? fStr,
            'colorValue': List? fColor,
          },
          'lastPoint': {
            'stamp': DateTime lStamp,
            'boolValue': bool? lBool,
            'intValue': int? lInt,
            'floatValue': double? lFlt,
            'stringValue': String? lStr,
            'colorValue': List? lColor,
          },
        }
            when totalPoints > 0 =>
          DeviceHistory._(
            totalPoints: totalPoints,
            summary: (
              Reading.fromParams(
                fStamp,
                fBool,
                fInt,
                fFlt,
                fStr,
                fColor?.cast<int>().toList(),
              ),
              Reading.fromParams(
                lStamp,
                lBool,
                lInt,
                lFlt,
                lStr,
                lColor?.cast<int>().toList(),
              ),
            ),
          ),
        _ => null,
      };
}
