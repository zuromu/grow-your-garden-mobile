import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grow_your_garden_mobile/screens/events_page.dart';
import 'package:grow_your_garden_mobile/services/event_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

const jsonHeaders = {'content-type': 'application/json'};

Map<String, dynamic> eventJson(String name) => {
      'id': name,
      'name': name,
      'description': 'd',
      'what_to_bring': '',
      'location': 'Menteng Urban Farm',
      'start_time': '2026-12-07T09:00:00+07:00',
      'end_time': '2026-12-07T12:00:00+07:00',
      'theme_plant': 'tomato',
      'theme_plant_name': 'Cherry tomato',
      'cover_photo_url': '',
      'host': 'ben',
      'status': 'open',
      'cover_url': '',
      'going_count': 27,
      'is_going': false,
    };

Widget app(MockClient client) =>
    MaterialApp(home: EventsPage(service: EventService(client: client)));

void main() {
  testWidgets('shows skeletons, then the event cards', (tester) async {
    await tester.pumpWidget(app(MockClient((request) async =>
        http.Response(jsonEncode([eventJson('Community Seed Swap')]), 200, headers: jsonHeaders))));
    expect(find.text('Community Seed Swap'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Community Seed Swap'), findsOneWidget);
    expect(find.text('CHERRY TOMATO'), findsOneWidget);
    expect(find.text('27 going'), findsOneWidget);
  });

  testWidgets('empty list shows the host message', (tester) async {
    await tester.pumpWidget(app(MockClient((request) async => http.Response('[]', 200, headers: jsonHeaders))));
    await tester.pumpAndSettle();
    expect(find.text('No upcoming events yet'), findsOneWidget);
  });

  testWidgets('an error shows one sentence and Try again loads again', (tester) async {
    var calls = 0;
    await tester.pumpWidget(app(MockClient((request) async {
      calls++;
      if (calls == 1) throw http.ClientException('offline');
      return http.Response(jsonEncode([eventJson('Back online')]), 200, headers: jsonHeaders);
    })));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load events"), findsOneWidget);
    expect(find.textContaining('internet'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Back online'), findsOneWidget);
  });

  testWidgets('filter pill asks the API for that filter', (tester) async {
    final asked = <String>[];
    await tester.pumpWidget(app(MockClient((request) async {
      asked.add(request.url.queryParameters['filter']!);
      return http.Response('[]', 200, headers: jsonHeaders);
    })));
    await tester.pumpAndSettle();
    await tester.tap(find.text('This month'));
    await tester.pumpAndSettle();
    expect(asked, ['upcoming', 'month']);
    expect(find.text('Nothing this month'), findsOneWidget);
  });

  testWidgets('search with no results offers Clear search', (tester) async {
    await tester.pumpWidget(app(MockClient((request) async => http.Response('[]', 200, headers: jsonHeaders))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zucchini');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('No events match "zucchini"'), findsOneWidget);
    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('No upcoming events yet'), findsOneWidget);
  });

  testWidgets('My events while logged out asks to log in', (tester) async {
    await tester.pumpWidget(app(MockClient((request) async => http.Response('[]', 200, headers: jsonHeaders))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My events'));
    await tester.pumpAndSettle();
    expect(find.text('Log in to see your events'), findsOneWidget);
  });
}