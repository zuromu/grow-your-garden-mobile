import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grow_your_garden_mobile/models/event.dart';
import 'package:grow_your_garden_mobile/screens/event_form_page.dart';
import 'package:grow_your_garden_mobile/screens/events_page.dart';
import 'package:grow_your_garden_mobile/services/event_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

const jsonHeaders = {'content-type': 'application/json'};
http.Response ok(Object body) => http.Response(jsonEncode(body), 200, headers: jsonHeaders);

const plants = [
  {'slug': 'tomato', 'name': 'Cherry tomato'},
  {'slug': 'basil', 'name': 'Sweet basil'},
];

final existing = Event(
  id: 'abc',
  name: 'Community Seed Swap',
  description: 'Bring seeds',
  location: 'Menteng Urban Farm',
  startTime: DateTime.now().add(const Duration(days: 3)).toUtc(),
  themePlant: 'tomato',
  host: 'ben',
);

Map<String, dynamic> savedJson(String name) => {
      'id': 'abc', 'name': name, 'description': 'Bring seeds', 'what_to_bring': '',
      'location': 'Menteng Urban Farm', 'start_time': existing.startTime.toIso8601String(), 'end_time': null,
      'theme_plant': 'tomato', 'theme_plant_name': 'Cherry tomato', 'cover_photo_url': '', 'host': 'ben',
      'status': 'open', 'cover_url': '', 'going_count': 0, 'is_going': false,
    };

// Opens the form from a button, so we can see what it pops with
Widget opener(EventService service, {Event? event, void Function(Object?)? onResult}) => MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EventFormPage(service: service, event: event)),
              );
              onResult?.call(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

void main() {
  // A tall test screen, so the whole form is built without scrolling
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first.physicalSize = const Size(1080, 4000);
  });
  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first.resetPhysicalSize();
  });

  testWidgets('sending an empty form shows the errors and calls no API', (tester) async {
    var posts = 0;
    final service = EventService(token: 't', client: MockClient((request) async {
      if (request.method == 'POST') posts++;
      return ok(plants);
    }));
    await tester.pumpWidget(MaterialApp(home: EventFormPage(service: service)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Host event'));
    await tester.pumpAndSettle();
    expect(find.text('Please give your event a name.'), findsOneWidget);
    expect(find.text('Please pick a date.'), findsOneWidget);
    expect(find.text('Please add a location.'), findsOneWidget);
    expect(posts, 0);
  });

  testWidgets('an http photo link is refused before sending', (tester) async {
    final service = EventService(token: 't', client: MockClient((request) async => ok(plants)));
    await tester.pumpWidget(MaterialApp(home: EventFormPage(service: service, event: existing)));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Cover photo link'), 'http://a.com/x.jpg');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Please paste a full image link, starting with https://'), findsOneWidget);
  });

  testWidgets('edit fills the form, sends only what changed and returns the saved event', (tester) async {
    Map<String, dynamic>? body;
    Object? result;
    final service = EventService(token: 't', client: MockClient((request) async {
      if (request.method == 'PATCH') {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return ok(savedJson('Tomato Night'));
      }
      return ok(plants);
    }));
    await tester.pumpWidget(opener(service, event: existing, onResult: (r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Edit event'), findsOneWidget);
    expect(find.text('Cherry tomato'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Event name'), 'Tomato Night');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(body!['name'], 'Tomato Night');
    expect(body!.containsKey('start_time'), isFalse);
    expect((result as Event).name, 'Tomato Night');
  });

  testWidgets('a server error shows under the right field', (tester) async {
    final service = EventService(token: 't', client: MockClient((request) async {
      if (request.method == 'PATCH') {
        return http.Response(jsonEncode({'location': ['This field may not be blank.']}), 400, headers: jsonHeaders);
      }
      return ok(plants);
    }));
    await tester.pumpWidget(MaterialApp(home: EventFormPage(service: service, event: existing)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('This field may not be blank.'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('closing with changes asks first', (tester) async {
    final service = EventService(token: 't', client: MockClient((request) async => ok(plants)));
    await tester.pumpWidget(opener(service, event: existing));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Event name'), 'Changed');
    await tester.pump();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Leave without saving?'), findsOneWidget);
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('a guest tapping Host an event is asked to log in', (tester) async {
    final service = EventService(client: MockClient((request) async => ok([])));
    await tester.pumpWidget(MaterialApp(home: EventsPage(service: service)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Host an event').first);
    await tester.pumpAndSettle();
    expect(find.text('Log in to host an event'), findsOneWidget);
  });
}