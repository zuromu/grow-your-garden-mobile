import 'package:flutter_test/flutter_test.dart';
import 'package:grow_your_garden_mobile/models/event.dart';

void main() {
  test('Event.fromJson reads the API fields', () {
    final event = Event.fromJson({
      'id': 'da8a6da4-cac6-4b77-915e-696d9b07e915',
      'name': 'Seed swap',
      'description': 'Bring seeds',
      'what_to_bring': '',
      'location': 'Menteng',
      'start_time': '2026-11-28T17:59:50.210122+07:00',
      'end_time': null,
      'theme_plant': null,
      'theme_plant_name': null,
      'cover_photo_url': '',
      'host': 'ben',
      'status': 'open',
      'cover_url': '',
      'going_count': 3,
      'is_going': true,
    });
    expect(event.name, 'Seed swap');
    expect(event.startTime.toUtc(), DateTime.utc(2026, 11, 28, 10, 59, 50, 210, 122));
    expect(event.endTime, isNull);
    expect(event.goingCount, 3);
    expect(event.isGoing, isTrue);
  });

  test('toJson only sends the fields the form can change', () {
    final event = Event(
      name: 'Seed swap',
      description: 'Bring seeds',
      location: 'Menteng',
      startTime: DateTime.utc(2026, 12, 1, 2),
      themePlant: 'tomato',
    );
    final json = event.toJson();
    expect(json['start_time'], '2026-12-01T02:00:00.000Z');
    expect(json['theme_plant'], 'tomato');
    expect(json.containsKey('id'), isFalse);
    expect(json.containsKey('going_count'), isFalse);
    expect(json.containsKey('host'), isFalse);
  });
}