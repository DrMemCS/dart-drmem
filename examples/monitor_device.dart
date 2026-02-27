import 'package:dart_drmem/dart_drmem.dart';

void main() async {
  // Define the connection parameters.
  // In a production environment, these might be discovered using mDNS.
  const host = '127.0.0.1';
  const port = 3000;
  const nodeName = 'test';
  const deviceName = 'my-device:enable';

  // Create the NodeInfo object.

  final nodeInfo = NodeInfo(
    name: nodeName,
    version: '0.0.0',
    location: 'unknown',
    addr: HostInfo(host, port),
  );

  // Initialize the DrMem service.

  final drmem = DrMemService(info: nodeInfo);

  try {
    print('Connecting to $nodeName at $host:$port...');
    print('Monitoring device: $deviceName\n');

    // Subscribe to device readings.
    // You can optionally specify time range:
    // final stream = drmem.monitorDevice(
    //   Device(name: deviceName),
    //   startTime: DateTime.now().subtract(Duration(hours: 1)),
    // );

    final stream = drmem.monitorDevice(Device(name: deviceName));

    // Listen to the stream with comprehensive error handling.

    int readingCount = 0;

    await for (final reading in stream) {
      readingCount++;
      print(
        'Reading #$readingCount at ${reading.stamp}: '
        '${_formatReading(reading)}',
      );

      // Optional: Cancel the subscription after receiving N readings
      if (readingCount >= 10) {
        print('\nReceived $readingCount readings. Stopping.');
        break;
      }
    }

    if (readingCount == 0) {
      print('No readings received. The subscription may have connected but');
      print('the server is not sending data in the expected format.');
    }
  } on DrMemNetworkException catch (e) {
    // Network-level errors: socket, HTTP connection, etc.
    print('Network Error: ${e.desc}');
    if (e.originalError != null) {
      print('  Original error: ${e.originalError}');
    }
  } on DrMemServerException catch (e) {
    // GraphQL server errors
    print('Server Error: ${e.desc}');
    if (e.originalError != null) {
      print('  Original error: ${e.originalError}');
    }
  } on DrMemStreamException catch (e) {
    // Stream-level errors: unexpected termination, data issues, etc.
    print('Stream Error: ${e.desc}');
    if (e.originalError != null) {
      print('  Original error: ${e.originalError}');
    }
    if (e.stackTrace != null) {
      print('  Stack trace: ${e.stackTrace}');
    }
  } catch (e) {
    // Catch any other unexpected errors
    print('Unexpected error: $e');
  } finally {
    // Ensure resources are cleaned up.
    await drmem.dispose();
    print('\nDisposed service resources.');
  }
}

/// Format a Reading object as a human-readable string.
String _formatReading(Reading reading) => switch (reading.value) {
  DevBool(value: bool b) => 'bool = $b',
  DevInt(value: int i) => 'int = $i',
  DevFlt(value: double d) => 'float = $d',
  DevStr(value: String s) => 'string = "$s"',
  DevColor(red: int r, green: int g, blue: int b, alpha: int a) =>
    'color = rgba($r, $g, $b, $a)',
};
