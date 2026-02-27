import 'package:dart_drmem/dart_drmem.dart';

void main() async {
  // Connection parameters - adjust for your environment.
  const host = '127.0.0.1';
  const port = 3000;
  const nodeName = 'demo';
  const deviceName = 'device:value';

  final nodeInfo = NodeInfo(
    name: nodeName,
    version: '0.0.0',
    location: 'unknown',
    addr: HostInfo(host, port),
  );

  final drmem = DrMemService(info: nodeInfo);

  try {
    print('Connecting to $nodeName at $host:$port...');

    // Build a value to send.  Change type as appropriate for the device.
    final value = DevFlt(value: 75.0);

    print('Setting device $deviceName -> $value');

    final reading = await drmem.setDevice(Device(name: deviceName), value);

    print('Device updated, new reading: $reading');
  } on DrMemNetworkException catch (e) {
    print('Network error while setting device: ${e.desc}');
  } on DrMemServerException catch (e) {
    print('Server error while setting device: ${e.desc}');
  } catch (e) {
    print('Unexpected error: $e');
  } finally {
    await drmem.dispose();
    print('Disposed service resources.');
  }
}
