import 'package:material_ui/material_ui.dart';

import '../models/event.dart';

// Colours from the website and the Figma design system
const eventBrand = Color(0xFF17653B);
const eventInk = Color(0xFF17241B);
const eventInkSoft = Color(0xFF536057);
const eventPage = Color(0xFFEEF0EA);
const eventTint = Color(0xFFE8F7DF);
const eventSoft = Color(0xFFBEFFB8);
const eventPink = Color(0xFFFFB8B9);

const _months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

String twoDigits(int n) => n.toString().padLeft(2, '0');

/// "09:00-12:00", or just "09:00" when there is no end time.
String eventTimeRange(Event event) {
  final start = event.startTime.toLocal();
  final text = '${twoDigits(start.hour)}:${twoDigits(start.minute)}';
  if (event.endTime == null) return text;
  final end = event.endTime!.toLocal();
  return '$text-${twoDigits(end.hour)}:${twoDigits(end.minute)}';
}

/// The photo, or a green box with a sprout when the event has no photo.
class EventCover extends StatelessWidget {
  const EventCover({super.key, required this.event, required this.height});

  final Event event;
  final double height;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      color: eventTint,
      alignment: Alignment.center,
      child: const Icon(Icons.spa_outlined, size: 40, color: eventBrand),
    );
    if (event.coverUrl.isEmpty) return placeholder;
    return Image.network(
      event.coverUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => placeholder,
    );
  }
}

/// The small white box with the day and month on top of the photo.
class DateBadge extends StatelessWidget {
  const DateBadge({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final local = date.toLocal();
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: eventInk, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(twoDigits(local.day), style: const TextStyle(fontSize: 20, color: eventInk)),
          Text(_months[local.month - 1],
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: eventBrand)),
        ],
      ),
    );
  }
}

/// One event in the list, like the Event Card in Figma.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.onTap});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: eventInk, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                EventCover(event: event, height: 160),
                Positioned(left: 12, bottom: 12, child: DateBadge(date: event.startTime)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.themePlantName != null) ...[
                    PlantTag(name: event.themePlantName!),
                    const SizedBox(height: 8),
                  ],
                  Text(event.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: eventInk)),
                  const SizedBox(height: 8),
                  _MetaRow(icon: Icons.schedule, text: eventTimeRange(event)),
                  const SizedBox(height: 4),
                  _MetaRow(icon: Icons.place_outlined, text: event.location),
                  const Divider(height: 24),
                  Text(
                    event.isGoing ? 'You + ${event.goingCount - 1} going' : '${event.goingCount} going',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: eventInk),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlantTag extends StatelessWidget {
  const PlantTag({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: eventPink, borderRadius: BorderRadius.circular(999)),
      child: Text(name.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: eventInk)),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: eventInkSoft),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: eventInkSoft))),
      ],
    );
  }
}

/// Grey blocks in the shape of an EventCard, shown while the list loads.
class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget line(double width, double height) => Container(
          width: width,
          height: height,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: eventTint, borderRadius: BorderRadius.circular(height / 2)),
        );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC1C8C1), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 160, color: eventTint),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [line(96, 18), line(220, 22), line(160, 12), line(180, 12)],
            ),
          ),
        ],
      ),
    );
  }
}