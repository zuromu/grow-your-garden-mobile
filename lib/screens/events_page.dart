import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';

/// The Plant Event list: search, filters, cards, and every empty or error state from Figma.
class EventsPage extends StatefulWidget {
  const EventsPage({super.key, this.service});

  // Tests pass a service with a fake http client
  final EventService? service;

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late final EventService _service = widget.service ?? EventService();
  final _searchController = TextEditingController();
  Timer? _searchTimer;

  String _filter = 'upcoming';
  String _query = '';
  late Future<List<Event>> _events = _load();

  static const _filters = {'upcoming': 'Upcoming', 'month': 'This month', 'mine': 'My events'};

  Future<List<Event>> _load() => _service.getEvents(filter: _filter, query: _query);

  // Braces matter: setState must not return the Future
  void _reload() {
    setState(() {
      _events = _load();
    });
  }

  void _setFilter(String filter) {
    _filter = filter;
    _reload();
  }

  // Wait until the user stops typing for a moment, so we don't call the API on every letter
  void _onSearchChanged(String text) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 400), () {
      _query = text.trim();
      _reload();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _query = '';
    _reload();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: eventPage,
      appBar: AppBar(title: const Text('Events'), backgroundColor: Colors.white),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Grow Your Garden', style: TextStyle(fontSize: 22))),
            ListTile(
              leading: const Icon(Icons.spa_outlined),
              title: const Text('Garden'),
              onTap: () => Navigator.pushReplacementNamed(context, '/garden'),
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('Events'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _events.catchError((_) => <Event>[]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by event or theme plant...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(999)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final entry in _filters.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _filter == entry.key,
                    selectedColor: eventSoft,
                    onSelected: (_) => _setFilter(entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Event>>(
              future: _events,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Column(
                    children: [EventCardSkeleton(), SizedBox(height: 16), EventCardSkeleton()],
                  );
                }
                if (snapshot.hasError) {
                  return MessageBox(
                    icon: Icons.close,
                    title: "Couldn't load events",
                    message: snapshot.error.toString(),
                    buttonLabel: 'Try again',
                    onPressed: _reload,
                  );
                }
                final events = snapshot.data!;
                if (events.isEmpty) return _emptyState();
                return Column(
                  children: [
                    for (final event in events) ...[
                      EventCard(event: event, onTap: () {}),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: eventBrand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Host an event'),
      ),
    );
  }

  // The right empty message for the search or filter the user picked
  Widget _emptyState() {
    if (_query.isNotEmpty) {
      return MessageBox(
        icon: Icons.search,
        title: 'No events match "$_query"',
        message: 'Try another word, or search by a plant name like tomato.',
        buttonLabel: 'Clear search',
        onPressed: _clearSearch,
      );
    }
    if (_filter == 'mine' && _service.token == null) {
      return MessageBox(
        icon: Icons.person_outline,
        title: 'Log in to see your events',
        message: 'Events you host or RSVP to will show up here.',
        buttonLabel: 'Log in',
        onPressed: () {},
      );
    }
    if (_filter == 'month') {
      return MessageBox(
        icon: Icons.event_outlined,
        title: 'Nothing this month',
        message: 'Upcoming shows the events after this month.',
        buttonLabel: 'See upcoming',
        onPressed: () => _setFilter('upcoming'),
      );
    }
    return MessageBox(
      icon: Icons.event_outlined,
      title: 'No upcoming events yet',
      message: 'Be the first to host one. Seed swaps, workshops and harvest days all count.',
      buttonLabel: 'Host an event',
      onPressed: () {},
    );
  }
}

/// The dashed box from Figma for empty and error states: icon, title, one sentence, one button.
class MessageBox extends StatelessWidget {
  const MessageBox({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: eventInk.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          CircleAvatar(backgroundColor: eventTint, child: Icon(icon, color: eventBrand)),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: eventInk)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: eventInkSoft)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(backgroundColor: eventBrand, minimumSize: const Size(0, 48)),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}