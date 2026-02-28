import 'dart:async';

import 'package:dart_drmem/dart_drmem.dart';
import 'package:graphql/client.dart';
import 'package:test/test.dart';

void main() {
  group('DrMemService (mocked GraphQL)', () {
    test('setDevice returns Reading with correct value and stamp', () async {
      final nodeInfo = NodeInfo(
        name: 'test',
        version: '0.0.0',
        location: 'here',
        addr: HostInfo('127.0.0.1', 3000),
      );

      // Mock mutate function
      Future<QueryResult> mockMutate(MutationOptions options) async {
        // Simulate the GraphQL mutation returning the setDevice payload
        final data = {
          'setDevice': {
            'stamp': '2026-02-28T12:00:00.000Z',
            'boolValue': null,
            'intValue': null,
            'floatValue': 75.0,
            'stringValue': null,
            'colorValue': null,
          },
        };
        return QueryResult(
          source: QueryResultSource.network,
          data: data,
          options: options,
        );
      }

      // For these tests we don't need query/subscribe; provide simple stubs.
      Future<QueryResult> mockQuery(QueryOptions options) async => QueryResult(
        source: QueryResultSource.network,
        data: {},
        options: options,
      );
      Stream<QueryResult> mockSubscribe(SubscriptionOptions options) =>
          const Stream.empty();

      final svc = DrMemService.test(
        info: nodeInfo,
        queryFn: mockQuery,
        mutateFn: mockMutate,
        subscribeFn: mockSubscribe,
      );

      final reading = await svc.setDevice(
        Device(name: 'dev'),
        DevFlt(value: 75.0),
      );

      expect(reading.stamp, DateTime.parse('2026-02-28T12:00:00.000Z'));
      expect((reading.value as DevFlt).value, closeTo(75.0, 1e-9));

      await svc.dispose();
    });

    test('getDriverInfo returns parsed drivers', () async {
      final nodeInfo = NodeInfo(
        name: 'test',
        version: '0.0.0',
        location: 'here',
        addr: HostInfo('127.0.0.1', 3000),
      );

      Future<QueryResult> mockQuery(QueryOptions options) async {
        final data = {
          'driverInfo': [
            {
              '__typename': 'DriverInfo',
              'name': 'drv',
              'summary': 'sum',
              'description': 'desc',
            },
          ],
        };
        return QueryResult(
          source: QueryResultSource.network,
          data: data,
          options: options,
        );
      }

      Future<QueryResult> mockMutate(MutationOptions options) async =>
          QueryResult(
            source: QueryResultSource.network,
            data: {},
            options: options,
          );
      Stream<QueryResult> mockSubscribe(SubscriptionOptions options) =>
          const Stream.empty();

      final svc = DrMemService.test(
        info: nodeInfo,
        queryFn: mockQuery,
        mutateFn: mockMutate,
        subscribeFn: mockSubscribe,
      );

      final drivers = await svc.getDriverInfo();

      expect(drivers, isNotEmpty);
      expect(drivers.first.name, 'drv');

      await svc.dispose();
    });

    test('monitorDevice yields readings from subscription', () async {
      final nodeInfo = NodeInfo(
        name: 'test',
        version: '0.0.0',
        location: 'here',
        addr: HostInfo('127.0.0.1', 3000),
      );

      Stream<QueryResult> mockSubscribe(SubscriptionOptions options) async* {
        final data = {
          'monitorDevice': {
            'stamp': '2026-02-28T12:10:00.000Z',
            'boolValue': null,
            'intValue': null,
            'floatValue': 50.0,
            'stringValue': null,
            'colorValue': null,
          },
        };
        yield QueryResult(
          source: QueryResultSource.network,
          data: data,
          options: options,
        );
      }

      Future<QueryResult> mockQuery(QueryOptions options) async => QueryResult(
        source: QueryResultSource.network,
        data: {},
        options: options,
      );
      Future<QueryResult> mockMutate(MutationOptions options) async =>
          QueryResult(
            source: QueryResultSource.network,
            data: {},
            options: options,
          );

      final svc = DrMemService.test(
        info: nodeInfo,
        queryFn: mockQuery,
        mutateFn: mockMutate,
        subscribeFn: mockSubscribe,
      );

      final stream = svc.monitorDevice(Device(name: 'dev'));
      final reading = await stream.first;
      expect((reading.value as DevFlt).value, closeTo(50.0, 1e-9));

      await svc.dispose();
    });
  });
}
