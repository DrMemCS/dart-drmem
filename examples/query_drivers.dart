import 'package:dart_drmem/src/drmem_service.dart';
import 'package:dart_drmem/src/node_info.dart';

void main() async {
  // Define the connection parameters.
  // In a production environment, these might be discovered using mDNS.
  const host = '127.0.0.1';
  const port = 3000;
  const nodeName = 'demo-node';

  // Create the NodeInfo object.
  // The version and location are typically populated from the node's
  // announcement, but for a direct connection, placeholders are sufficient.
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

    // Query the configured drivers.
    final drivers = await drmem.getDriverInfo();

    if (drivers.isEmpty) {
      print('No drivers configured.');
    } else {
      print('Found ${drivers.length} drivers:');
      for (final driver in drivers) {
        print('\n[${driver.name}]');
        print('  Summary:     ${driver.summary}');
        print('  Description: ${driver.description}');
      }
    }
  } catch (e) {
    print('Error querying drivers: $e');
  } finally {
    // Ensure resources are cleaned up.
    await drmem.dispose();
  }
}
