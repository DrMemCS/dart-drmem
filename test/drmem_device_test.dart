import 'package:dart_drmem/dart_drmem.dart';
import 'package:test/test.dart';

void main() {
  test("... Device construction", () {
    expect(() => Device(name: "a"), returnsNormally);
    expect(() => Device(name: "ab"), returnsNormally);
    expect(() => Device(name: "a:b"), returnsNormally);
    expect(() => Device(name: "a:b:c"), returnsNormally);
    expect(() => Device(name: "0"), returnsNormally);
    expect(() => Device(name: "01"), returnsNormally);
    expect(() => Device(name: "0:1"), returnsNormally);
    expect(() => Device(name: "0:1:2"), returnsNormally);
    expect(() => Device(name: "a-b"), returnsNormally);

    expect(() => Device(name: ""), throwsA(isArgumentError));
    expect(() => Device(name: "."), throwsA(isArgumentError));
    expect(() => Device(name: ":"), throwsA(isArgumentError));
    expect(() => Device(name: ":a"), throwsA(isArgumentError));
    expect(() => Device(name: "::"), throwsA(isArgumentError));
    expect(() => Device(name: "a::"), throwsA(isArgumentError));
    expect(() => Device(name: "::b"), throwsA(isArgumentError));
    expect(() => Device(name: ":"), throwsA(isArgumentError));
    expect(() => Device(name: "-a"), throwsA(isArgumentError));
    expect(() => Device(name: "a-"), throwsA(isArgumentError));
    expect(() => Device(name: "-a:b"), throwsA(isArgumentError));
    expect(() => Device(name: "a-:b"), throwsA(isArgumentError));
    expect(() => Device(name: "a:-b"), throwsA(isArgumentError));
    expect(() => Device(name: "a:b-"), throwsA(isArgumentError));
  });

  test("... Device comparisons", () {
    // Make sure comparisons work for devices without a node specified.

    expect(Device(name: "a").compareTo(Device(name: "a")), equals(0));
    expect(Device(name: "b").compareTo(Device(name: "a")), equals(1));
    expect(Device(name: "a").compareTo(Device(name: "b")), equals(-1));
  });
}
