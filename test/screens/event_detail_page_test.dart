import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grow_your_garden_mobile/screens/event_detail_page.dart';
import 'package:grow_your_garden_mobile/services/event_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

const jsonHeaders = {'content-type': 'application/json'};

Map<String, dynamic> eventJson({String status = 'open', int going = 27, bool isGoing = false}) => {
      'id': 'abc',
      'name': 'Community Seed Swap',
      'description': 'Bring the seeds you saved.',
      'what_to_bring': 'Seeds in envelopes\nA reusable bag',
      'location': 'Menteng Urban Farm',
      'start_time': '2026-11-07T09:00:00+07:00',
      'end_time': '2026-11-07T12:00:00+07:00',
      'theme_plant': 'tomato',
      'theme_plant_name': 'Cherry tomato',
      'cover_photo_url': '',
      'host': 'ben',
      'status': status,
      'cover_url': '',
      'going_count': going,
      'is_going': isGoing,
    };

http.Response ok(Object body) => http.Response(jsonEncode(body), 200, headers: jsonHeaders);

Widget app(MockClient client, {String? token, String? username}) => MaterialApp(
      home: EventDetailPage(eventId: 'abc', service: EventService(client: client, token: token), username: username),
    );

void main() {
  testWidgets('shows the event info and what to bring', (tester) async {
    await tester.pumpWidget(app(MockClient((request) async => ok(eventJson()))));
    await tester.pumpAndSettle();
    expect(find.text('Community Seed Swap'), findsOneWidget);
    expect(find.text('Saturday, 7 November 2026'), findsOneWidget);
    expect(find.text('A reusable bag'), findsOneWidget);
    expect(find.text('27 going'), findsOneWidget);
  });

  testWidgets('a guest tapping RSVP is asked to log in', (tester) async {
    await tester.pumpWidget(app(MockClient((request) async => ok(eventJson()))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RSVP'));
    await tester.pumpAndSettle();
    expect(find.text('Log in to RSVP'), findsOneWidget);
  });

  testWidgets('RSVP shows Going right away and keeps it when the server agrees', (tester) async {
    await tester.pumpWidget(app(token: 't', MockClient((request) async {
      if (request.method == 'POST') return ok(eventJson(going: 28, isGoing: true));
      return ok(eventJson());
    })));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RSVP'));
    await tester.pump();
    expect(find.text('You + 27 going'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Going ✓'), findsOneWidget);
  });

  testWidgets('a failed RSVP goes back and says why', (tester) async {
    await tester.pumpWidget(app(token: 't', MockClient((request) async {
      if (request.method == 'POST') throw http.ClientException('offline');
      return ok(eventJson());
    })));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RSVP'));
    await tester.pumpAndSettle();
    expect(find.text('27 going'), findsOneWidget);
    expect(find.textContaining("Couldn't save your RSVP"), findsOneWidget);
  });

  testWidgets('an ended event cannot be RSVPed', (tester) async {
    await tester.pumpWidget(app(token: 't', MockClient((request) async => ok(eventJson(status: 'ended')))));
    await tester.pumpAndSettle();
    expect(find.text('27 went'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Ended'));
    expect(button.onPressed, isNull);
  });

  testWidgets('the host can delete after confirming', (tester) async {
    var deleted = false;
    await tester.pumpWidget(app(token: 't', username: 'ben', MockClient((request) async {
      if (request.method == 'DELETE') {
        deleted = true;
        return http.Response('', 204);
      }
      return ok(eventJson());
    })));
    await tester.pumpAndSettle();
    expect(find.text('Edit event'), findsOneWidget);
    await tester.tap(find.text('Delete event'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this event?'), findsOneWidget);
    await tester.tap(find.text('Yes, delete'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });

  testWidgets('a deleted event explains itself', (tester) async {
    await tester.pumpWidget(app(MockClient((request) async =>
        http.Response('{"detail":"Not found."}', 404, headers: jsonHeaders))));
    await tester.pumpAndSettle();
    expect(find.text("This event isn't here anymore"), findsOneWidget);
  });
}