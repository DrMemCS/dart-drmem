import 'package:dart_drmem/src/device_like.dart';
import 'package:dart_drmem/src/drmem_service.dart';
import 'package:dart_drmem/src/node_info.dart';

void main() async {
  // Define the connection parameters.
  // In a production environment, these might be discovered using mDNS.
  const host = '127.0.0.1';
  const port = 3000;
  const nodeName = 'drmem-demo';

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

    // Query the configured devices.
    // The '*' pattern matches all devices.
    final devices = await drmem.getDeviceInfo(device: DevicePattern(name: '*'));

    // Sort the devices by name.
    devices.sort((a, b) => a.device.name.compareTo(b.device.name));

    if (devices.isEmpty) {
      print('No devices configured.');
    } else {
      print('Found ${devices.length} devices:');
      for (final info in devices) {
        print('\n[${info.device.name}]');
        print('  Settable: ${info.settable}');
        if (info.units != null) {
          print('  Units:    ${info.units}');
        }
      }
    }
  } catch (e) {
    print('Error querying devices: $e');
  } finally {
    // Ensure resources are cleaned up.
    await drmem.dispose();
  }
}
