import 'dart:async';
import 'dart:io';

import 'package:dart_drmem/src/device_history.dart';
import 'package:http/io_client.dart';
import 'package:graphql/client.dart';
import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/io.dart';

import 'client_id.dart';
import 'node_info.dart';
import 'device_like.dart';
import 'device_info.dart';
import 'driver_info.dart';
import 'device_value.dart';
import 'reading.dart';

import "dart:developer" as dev;

extension on DevValue {
  Map<String, dynamic> toGqlInput() => switch (this) {
    DevBool(value: bool v) => {'boolValue': v},
    DevInt(value: int v) => {'intValue': v},
    DevFlt(value: double v) => {'floatValue': v},
    DevStr(value: String v) => {'stringValue': v},
    DevColor(red: int r, green: int g, blue: int b, alpha: int a) => {
      'colorValue': [r, g, b, a],
    },
  };
}

/// Class which communicates with a DrMem node.
class DrMemService {
  final String _node;
  final (GraphQLClient, GraphQLClient) _handles;

  /// Creates an instance of the class.
  DrMemService({required NodeInfo info, ClientID? clientId})
    : _node = info.name,
      _handles = _createConnection(info, clientId);

  GraphQLClient get q => _handles.$1;
  GraphQLClient get s => _handles.$2;

  /// Clean up resources.
  /// This method should be called by the owner when the service is no longer
  /// needed.

  Future<void> dispose() async {
    await Future.wait([_handles.$1.link.dispose(), _handles.$2.link.dispose()]);
  }

  // Helper function to create the GraphQL query URIs.

  static (Uri, Uri) _buildUris({
    required HostInfo addr,
    required String qEnd,
    required String sEnd,
    bool encrypted = false,
  }) => (
    Uri(
      scheme: encrypted ? "https" : "http",
      host: addr.host,
      port: addr.port,
      path: qEnd,
    ),
    Uri(
      scheme: encrypted ? "wss" : "ws",
      host: addr.host,
      port: addr.port,
      path: sEnd,
    ),
  );

  // Creates two `Client` connections that will connect to the specified node.
  // If an encrypted channel is requested, the client's ID is passed along.

  static (GraphQLClient, GraphQLClient) _createConnection(
    NodeInfo info,
    ClientID? id,
  ) {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          // This validates certificates that aren't recognized by Root
          // Authorities. Early DrMem instances only announced the SHA-1
          // fingerprint, so if the MD5 signature is empty, we simply
          // accept that portion. Later versions use both digests and we
          // will compare both.
          (X509Certificate cert, String host, int port) {
            dev.log(
              "badCertificateCallback invoked for host: $host, port: $port",
              name: "DrMem.ConnectCert",
            );

            final expectedPort = info.addr.port;

            if (info.signatures case (
              String md5Expected,
              String sha256Expected,
            )) {
              final actualMd5 = md5.convert(cert.der).toString();
              final actualSha256 = sha256.convert(cert.der).toString();
              final portMatch = port == expectedPort;

              // Legacy support: if MD5 in NodeInfo is empty, we don't check it.

              final md5Match =
                  (md5Expected.isEmpty || md5Expected == actualMd5);
              final sha256Match = actualSha256 == sha256Expected;
              final decision = portMatch && md5Match && sha256Match;

              dev.log(r'''
badCertificateCallback:
    Host: $host:$port (Expected Port: $expectedPort -> Match: $portMatch)
    MD5: Expected='$md5Expected', Actual='$actualMd5' -> Match: $md5Match
    SHA256: Expected='$sha256Expected', Actual='$actualSha256' -> Match: $sha256Match
    Overall Decision: $decision
''', name: "DrMem.ConnectCert");
              return decision;
            } else {
              // This implies an unencrypted connection was expected (http/ws),
              // but we're in a callback for an https/wss attempt. Or, it's an
              // encrypted connection (https/wss) but NodeInfo is missing
              // signatures.

              dev.log(
                "badCertificateCallback: Signatures not available in NodeInfo. Forcing rejection for safety.",
                name: "DrMem.ConnectCert",
              );
              return false;
            }
          };

    final encrypted = info.signatures != null;
    final (qUri, sUri) = _buildUris(
      addr: info.addr,
      qEnd: info.queries,
      sEnd: info.subscriptions,
      encrypted: encrypted,
    );

    dev.log("Connecting to Query URI: $qUri", name: "DrMem.Connect");
    dev.log("Connecting to Subscription URI: $sUri", name: "DrMem.Connect");

    final Map<String, String> headers = encrypted && id != null
        ? {'X-DrMem-Client-Id': id.fingerprint}
        : {};
    final qClient = GraphQLClient(
      link: HttpLink(
        qUri.toString(),
        defaultHeaders: headers,
        httpClient: IOClient(httpClient),
      ),
      cache: GraphQLCache(),
    );
    final sClient = GraphQLClient(
      link: WebSocketLink(
        sUri.toString(),
        subProtocol: "graphql-ws",
        config: SocketClientConfig(
          autoReconnect: true,
          headers: headers,
          queryAndMutationTimeout: Duration(seconds: 2),
          connectFn: (url, protocols) async {
            final socket = await WebSocket.connect(
              url.toString(),
              protocols: protocols,
              headers: headers,
              customClient: httpClient,
            );
            return IOWebSocketChannel(socket);
          },
        ),
      ),
      cache: GraphQLCache(),
    );

    return (qClient, sClient);
  }

  static const String _mutateSetDevice = r'''
mutation SetDevice($device: String!, $value: SettingData!) {
  setDevice(device: $device, value: $value) {
    __typename
    stamp
    boolValue
    intValue
    floatValue
    stringValue
    colorValue
  }
}''';

  // The implementation of [DrMem.setDevice].

  Future<Reading> setDevice(Device device, DevValue value) async {
    final MutationOptions options = MutationOptions(
      document: gql(_mutateSetDevice),
      variables: {'device': device.name, 'value': value.toGqlInput()},
    );
    final QueryResult result = await q.mutate(options);

    if (result.hasException) {
      throw (result.exception!);
    }

    return Reading.fromParams(
      result.data!['stamp'],
      result.data!['boolValue'],
      result.data!['intValue'],
      result.data!['floatValue'],
      result.data!['stringValue'],
      result.data!['colorValue'],
    );
  }

  static const String _queryAllDrivers = r'''
query AllDrivers {
  driverInfo {
    __typename
    name
    summary
    description
  }
}''';

  static DriverInfo? _toDriverInfo(Map<String, dynamic> json) => switch (json) {
    {
      'name': String name,
      'summary': String summary,
      'description': String description,
    } =>
      DriverInfo(name, summary, description),
    _ => null,
  };

  Future<List<DriverInfo>> getDriverInfo(String node) async {
    final QueryOptions options = QueryOptions(document: gql(_queryAllDrivers));
    final QueryResult result = await q.query(options);

    if (result.hasException) {
      throw (result.exception!);
    }

    final List<DriverInfo>? drivers =
        (result.data?['driverInfo'] as List<Map<String, dynamic>>?)
            ?.map(_toDriverInfo)
            .nonNulls
            .toList()
          ?..sort((DriverInfo a, DriverInfo b) => a.name.compareTo(b.name));

    return drivers ?? [];
  }

  static const String _queryGetDeviceInfo = r'''
query GetDevice($name: String!) {
  deviceInfo(pattern: $name) {
    deviceName
    settable
    units
    history {
      totalPoints
      firstPoint {
        stamp
        boolValue
        intValue
        floatValue
        stringValue
        colorValue
      }
      lastPoint {
        stamp
        boolValue
        intValue
        floatValue
        stringValue
        colorValue
      }
    }
  }
}''';

  DeviceHistory _toDevHistory(Map<String, dynamic>? json) => switch (json) {
    {
      'totalPoints': int totalPoints,
      'firstPoint': {
        'stamp': DateTime fStamp,
        'boolValue': bool? fBool,
        'intValue': int? fInt,
        'floatValue': double? fFlt,
        'stringValue': String? fStr,
        'colorValue': List<int>? fColor,
      },
      'lastPoint': {
        'stamp': DateTime lStamp,
        'boolValue': bool? lBool,
        'intValue': int? lInt,
        'floatValue': double? lFlt,
        'stringValue': String? lStr,
        'colorValue': List<int>? lColor,
      },
    } =>
      DeviceHistory(
        totalPoints: totalPoints,
        summary: (
          Reading.fromParams(fStamp, fBool, fInt, fFlt, fStr, fColor),
          Reading.fromParams(lStamp, lBool, lInt, lFlt, lStr, lColor),
        ),
      ),
    _ => DeviceHistory(totalPoints: 0),
  };

  DeviceInfo? Function(Map<String, dynamic>) _toDevInfo() =>
      (Map<String, dynamic> json) {
        if (json case {
          'deviceName': String name,
          'settable': bool settable,
          'units': String? units,
          'history': Map<String, dynamic>? history,
        }) {
          return DeviceInfo(
            Device(name: name, node: _node),
            settable,
            units,
            _toDevHistory(history),
          );
        } else {
          return null;
        }
      };

  // This is the implementation of [DrMem.getDeviceInfo].

  Future<List<DeviceInfo>> getDeviceInfo({
    required DevicePattern device,
  }) async {
    final QueryOptions options = QueryOptions(
      document: gql(_queryGetDeviceInfo),
      variables: {'name': device.name},
    );
    final QueryResult result = await q.query(options);

    if (result.hasException) {
      throw (result.exception!);
    }

    final List<DeviceInfo>? devices =
        (result.data?['deviceInfo'] as List<Map<String, dynamic>>?)
            ?.map(_toDevInfo())
            .nonNulls
            .toList()
          ?..sort((DeviceInfo a, DeviceInfo b) => a.device.compareTo(b.device));

    return devices ?? [];
  }

  static const String _subscriptionMonitorDevice = r'''
subscription MonitorDevice($device: String!, $range: DateRange) {
  monitorDevice(device: $device, range: $range) {
    stamp
    boolValue
    intValue
    floatValue
    stringValue
    colorValue
  }
}''';

  // Returns an appropriate GDateRangeBuilder based on the two input dates.
  // In DrMem's GraphQL API, if both dates are `null`, we don't provide a
  // date range (i.e. `null`). Otherwise we return a builder (possibly with
  // one of the date fields `null`.)

  Map<String, dynamic>? _buildDateRange(DateTime? a, DateTime? b) =>
      (a != null || b != null) ? {'start': a, 'end': b} : null;

  // The implementation of [DrMem.monitorDevice].

  Stream<Reading> monitorDevice(
    Device device, {
    DateTime? startTime,
    DateTime? endTime,
  }) async* {
    final options = SubscriptionOptions(
      document: gql(_subscriptionMonitorDevice),
      variables: {
        'device': device.name,
        'range': _buildDateRange(startTime, endTime),
      },
    );

    final strm = _handles.$2.subscribe(options);

    await for (final event in strm) {
      if (event.hasException) {
        throw (event.exception!);
      }

      switch (event.data) {
        case null:
          {}

        case {
          'stamp': DateTime stamp,
          'boolValue': bool? boolValue,
          'intValue': int? intValue,
          'floatValue': double? floatValue,
          'stringValue': String? stringValue,
          'colorValue': List<int>? colorValue,
        }:
          yield Reading.fromParams(
            stamp,
            boolValue,
            intValue,
            floatValue,
            stringValue,
            colorValue?.toList(),
          );

        case _:
          dev.log("data doesn't follow form.");
      }
    }
  }
}
