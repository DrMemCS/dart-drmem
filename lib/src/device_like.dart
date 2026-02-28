library;

/// Base class for Device-like types. All device-like types have a "name" field.
sealed class DeviceLike {
  final String name;

  const DeviceLike({required this.name});
}

/// Identifies a DrMem device by its name. The name must follow the DrMem
/// device name syntax (e.g., `motor:X:pos`). This class validates the name
/// format upon construction.
class Device extends DeviceLike {
  static String _validateName(String name) {
    final regexp = RegExp(r'^\w([-\w]*\w)?(:\w([-\w]*\w)?)*$', unicode: true);

    if (regexp.hasMatch(name)) {
      return name;
    } else {
      throw ArgumentError("invalid device name", "name");
    }
  }

  Device({required String name}) : super(name: _validateName(name));

  /// Define a comparison method.

  int compareTo(Device o) {
    return name.compareTo(o.name);
  }

  DevicePattern toPattern() => DevicePattern(name: name);
}

/// Defines a device "pattern" device. In this type, the name field can be
/// a unique device name or can be a name pattern using "glob" syntax (e.g.,
/// `motor:X:*`).
class DevicePattern extends DeviceLike {
  const DevicePattern({required super.name});
}
