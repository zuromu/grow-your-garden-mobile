import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grow_your_garden_mobile/models/event.dart';
import 'package:grow_your_garden_mobile/services/event_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const jsonHeaders = {'content-type': 'application/json'};

Map<String, dynamic> eventJson({String name = 'Seed swap', int going = 0, bool isGoing = false}) => {
      'id': 'abc',
      'name': name,
      'description': 'Bring seeds',
      'what_to_bring': '',
      'location': 'Menteng',
      'start_time': '2026-12-01T09:00:00+07:00',
      'end_time': null,
      'theme_plant': null,
      'theme_plant_name': null,
      'cover_photo_url': '',
      'host': 'ben',
      'status': 'open',
      'cover_url': '',
      'going_count': going,
      'is_going': isGoing,
    };

void main() {
  test('getEvents sends the filter and search, and reads the list', () async {
    late Uri asked;
    final service = EventService(client: MockClient((request) async {
      asked = request.url;
      return http.Response(jsonEncode([eventJson()]), 200, headers: jsonHeaders);
    }));
    final events = await service.getEvents(filter: 'month', query: 'seed');
    expect(asked.path, '/events/api/');
    expect(asked.queryParameters, {'filter': 'month', 'q': 'seed'});
    expect(events.single.name, 'Seed swap');
  });

  test('rsvp sends going and the login token', () async {
    late http.Request sent;
    final service = EventService(token: 'abc123', client: MockClient((request) async {
      sent = request;
      return http.Response(jsonEncode(eventJson(going: 1, isGoing: true)), 200, headers: jsonHeaders);
    }));
    final event = await service.rsvp('abc', going: true);
    expect(sent.url.path, '/events/api/abc/rsvp/');
    expect(jsonDecode(sent.body), {'going': true});
    expect(sent.headers['Authorization'], 'Token abc123');
    expect(event.isGoing, isTrue);
  });

  test('form errors come back per field', () async {
    final service = EventService(client: MockClient((request) async => http.Response(
        jsonEncode({'start_time': ['This date and time has already passed. Please pick a later one.']}), 400,
        headers: jsonHeaders)));
    final event = Event(name: 'x', description: 'd', location: 'l', startTime: DateTime(2020));
    expect(
      () => service.createEvent(event),
      throwsA(isA<ApiException>().having((e) => e.fieldErrors['start_time'], 'start_time', contains('already passed'))),
    );
  });

  test('a guest gets a plain log in message', () async {
    final service = EventService(client: MockClient((request) async => http.Response(
        jsonEncode({'detail': 'Authentication credentials were not provided.'}), 403, headers: jsonHeaders)));
    expect(() => service.rsvp('abc', going: true),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Please log in first.')));
  });

  test('the host message from the API is shown as it is', () async {
    final service = EventService(client: MockClient((request) async => http.Response(
        jsonEncode({'detail': 'Only the host can edit this event.'}), 403, headers: jsonHeaders)));
    final event = Event(name: 'x', description: 'd', location: 'l', startTime: DateTime(2030));
    expect(() => service.updateEvent('abc', event),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Only the host can edit this event.')));
  });

  test('a deleted event says so', () async {
    final service = EventService(client: MockClient((request) async => http.Response('{"detail":"Not found."}', 404, headers: jsonHeaders)));
    expect(() => service.getEvent('gone'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', "This event isn't here anymore.")));
  });

  test('a wifi login page is not read as JSON', () async {
    final service = EventService(client: MockClient((request) async => http.Response('<html>Hotel wifi</html>', 200, headers: {'content-type': 'text/html'})));
    expect(() => service.getEvents(), throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('public wifi'))));
  });

  test('no internet gives a plain message', () async {
    final service = EventService(client: MockClient((request) async => throw http.ClientException('Connection failed')));
    expect(() => service.getEvents(), throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('internet'))));
  });

  test('delete accepts 204 with no body', () async {
    final service = EventService(client: MockClient((request) async => http.Response('', 204)));
    await service.deleteEvent('abc');
  });
}