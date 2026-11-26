import 'package:json_annotation/json_annotation.dart';

part 'event.g.dart';

/// A Plant Event from the Django API (/events/api/).
@JsonSerializable(fieldRename: FieldRename.snake)
class Event {
  const Event({
    this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.startTime,
    this.endTime,
    this.whatToBring = '',
    this.themePlant,
    this.themePlantName,
    this.coverPhotoUrl = '',
    this.host = '',
    this.status = 'open',
    this.coverUrl = '',
    this.goingCount = 0,
    this.isGoing = false,
  });

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  // Set by the server, so they are never sent back
  @JsonKey(includeToJson: false)
  final String? id;
  final String name;
  final String description;
  @JsonKey(defaultValue: '')
  final String whatToBring;
  final String location;
  final DateTime startTime;
  final DateTime? endTime;
  // The plant's slug, like "tomato", or null for no theme plant
  final String? themePlant;
  @JsonKey(includeToJson: false)
  final String? themePlantName;
  @JsonKey(defaultValue: '')
  final String coverPhotoUrl;
  @JsonKey(includeToJson: false, defaultValue: '')
  final String host;
  // "open", "happening" or "ended"
  @JsonKey(includeToJson: false, defaultValue: 'open')
  final String status;
  @JsonKey(includeToJson: false, defaultValue: '')
  final String coverUrl;
  @JsonKey(includeToJson: false, defaultValue: 0)
  final int goingCount;
  @JsonKey(includeToJson: false, defaultValue: false)
  final bool isGoing;

  Map<String, dynamic> toJson() => _$EventToJson(this);
}