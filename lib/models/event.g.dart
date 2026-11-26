// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event(
  id: json['id'] as String?,
  name: json['name'] as String,
  description: json['description'] as String,
  location: json['location'] as String,
  startTime: DateTime.parse(json['start_time'] as String),
  endTime: json['end_time'] == null
      ? null
      : DateTime.parse(json['end_time'] as String),
  whatToBring: json['what_to_bring'] as String? ?? '',
  themePlant: json['theme_plant'] as String?,
  themePlantName: json['theme_plant_name'] as String?,
  coverPhotoUrl: json['cover_photo_url'] as String? ?? '',
  host: json['host'] as String? ?? '',
  status: json['status'] as String? ?? 'open',
  coverUrl: json['cover_url'] as String? ?? '',
  goingCount: (json['going_count'] as num?)?.toInt() ?? 0,
  isGoing: json['is_going'] as bool? ?? false,
);

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'what_to_bring': instance.whatToBring,
  'location': instance.location,
  'start_time': instance.startTime.toIso8601String(),
  'end_time': instance.endTime?.toIso8601String(),
  'theme_plant': instance.themePlant,
  'cover_photo_url': instance.coverPhotoUrl,
};
