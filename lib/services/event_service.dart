import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/event.dart';

/// An error the screen can show as it is: one plain sentence.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  final String message;
  final int? statusCode;
  // For the form: {"start_time": "This date and time has already passed..."}
  final Map<String, String> fieldErrors;

  @override
  String toString() => message;
}

/// A plant the host can pick as the event's theme.
class PlantChoice {
  const PlantChoice(this.slug, this.name);

  final String slug;
  final String name;
}

/// Talks to the Plant Event API (/events/api/) in the Django repo.
class EventService {
  EventService({http.Client? client, this.token}) : _client = client ?? http.Client();

  // Same address as GardenService. Change it with --dart-define=API_BASE_URL=...
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://william-jesiel-growyourgarden.pws.cs.ui.ac.id',
  );

  final http.Client _client;
  // Login token, null when logged out
  final String? token;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  /// filter is "upcoming", "month" or "mine", like the website.
  Future<List<Event>> getEvents({String filter = 'upcoming', String query = ''}) async {
    final params = {'filter': filter, if (query.isNotEmpty) 'q': query};
    final response = await _send(() => _client.get(_uri('/events/api/', params), headers: _headers));
    final data = jsonDecode(response.body) as List;
    return data.map((item) => Event.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Event> getEvent(String id) async {
    final response = await _send(() => _client.get(_uri('/events/api/$id/'), headers: _headers));
    return Event.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Event> createEvent(Event event) async {
    final response = await _send(() => _client.post(_uri('/events/api/'),
        headers: _headers, body: jsonEncode(event.toJson())));
    return Event.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// sendStartTime: false when the host did not change the start, so an event
  /// that already started can still get its text fixed (same rule as the website).
  Future<Event> updateEvent(String id, Event event, {bool sendStartTime = true}) async {
    final body = event.toJson();
    if (!sendStartTime) body.remove('start_time');
    final response = await _send(() => _client.patch(_uri('/events/api/$id/'),
        headers: _headers, body: jsonEncode(body)));
    return Event.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  
  Future<List<PlantChoice>> getPlantChoices() async {
    final response = await _send(() => _client.get(_uri('/events/api/plants/'), headers: _headers));
    final data = jsonDecode(response.body) as List;
    return data.map((item) => PlantChoice(item['slug'] as String, item['name'] as String)).toList();
  }

  Future<void> deleteEvent(String id) async {
    await _send(() => _client.delete(_uri('/events/api/$id/'), headers: _headers));
  }

  /// going: true to join, false to cancel. Returns the event with the new going count.
  Future<Event> rsvp(String id, {required bool going}) async {
    final response = await _send(() => _client.post(_uri('/events/api/$id/rsvp/'),
        headers: _headers, body: jsonEncode({'going': going})));
    return Event.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw ApiException('The server is taking too long. Try again in a moment.');
    } on http.ClientException {
      throw ApiException("Couldn't reach the server. Check your internet connection.");
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Campus or hotel wifi can answer with its own login page instead of our JSON
      final type = response.headers['content-type'] ?? '';
      if (response.statusCode != 204 && !type.contains('application/json')) {
        throw ApiException("Got an odd answer from the server. If you're on public wifi, log in to it first.");
      }
      return response;
    }
    throw _error(response);
  }

  ApiException _error(http.Response response) {
    final code = response.statusCode;
    final fieldErrors = <String, String>{};
    String? detail;
    try {
      final data = jsonDecode(response.body);
      if (data is Map) {
        if (data['detail'] is String) detail = data['detail'] as String;
        data.forEach((key, value) {
          if (value is List && value.isNotEmpty) fieldErrors[key as String] = value.first.toString();
        });
      }
    } on FormatException {
      // Not JSON, use the general message below
    }

    if (code == 401 || (code == 403 && (detail == null || detail.contains('credentials')))) {
      return ApiException('Please log in first.', statusCode: code);
    }
    if (code == 404) {
      return ApiException("This event isn't here anymore.", statusCode: code);
    }
    if (detail != null) return ApiException(detail, statusCode: code);
    if (fieldErrors.isNotEmpty) {
      return ApiException('Please check the form.', statusCode: code, fieldErrors: fieldErrors);
    }
    return ApiException('Something went wrong on the server. Try again.', statusCode: code);
  }
}