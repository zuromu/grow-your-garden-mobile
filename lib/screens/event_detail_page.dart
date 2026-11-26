import 'package:material_ui/material_ui.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';
import 'events_page.dart';

const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
  'September', 'October', 'November', 'December'];

/// "Saturday, 7 November 2026"
String longDate(DateTime date) {
  final d = date.toLocal();
  return '${_days[d.weekday - 1]}, ${d.day} ${_monthNames[d.month - 1]} ${d.year}';
}

/// One event: photo, info, what to bring, host, and the sticky RSVP or host bar from Figma.
class EventDetailPage extends StatefulWidget {
  const EventDetailPage({super.key, required this.eventId, this.service, this.username});

  final String eventId;
  final EventService? service;
  // The logged-in user's username, null for guests. Used to know if this user is the host.
  final String? username;

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late final EventService _service = widget.service ?? EventService();
  late Future<Event> _future = _service.getEvent(widget.eventId);
  // The newest copy of the event after an RSVP, shown instead of the loaded one
  Event? _event;
  bool _busy = false;

  void _reload() {
    setState(() {
      _event = null;
      _future = _service.getEvent(widget.eventId);
    });
  }

  bool get _loggedIn => _service.token != null;

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _rsvp(Event event, bool going) async {
    // Change the screen right away, then undo it if the server says no
    setState(() {
      _busy = true;
      _event = _copyWithGoing(event, going);
    });
    try {
      final saved = await _service.rsvp(event.id!, going: going);
      if (!mounted) return;
      setState(() => _event = saved);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _event = event);
      _toast("Couldn't save your RSVP. ${error.message}");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Event _copyWithGoing(Event e, bool going) => Event(
        id: e.id, name: e.name, description: e.description, location: e.location,
        startTime: e.startTime, endTime: e.endTime, whatToBring: e.whatToBring,
        themePlant: e.themePlant, themePlantName: e.themePlantName, coverPhotoUrl: e.coverPhotoUrl,
        host: e.host, status: e.status, coverUrl: e.coverUrl,
        goingCount: e.goingCount + (going ? 1 : -1), isGoing: going,
      );

  void _askToLogIn() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => _SheetBody(
        title: 'Log in to RSVP',
        children: [
          const Text("You need an account to join events. You'll come right back to this event after logging in."),
          const SizedBox(height: 16),
          // Log in opens the login page once the team's token login is ready
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(backgroundColor: eventBrand, minimumSize: const Size.fromHeight(48)),
            child: const Text('Log in'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }

  void _askToCancel(Event event) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _SheetBody(
        title: "You're going",
        children: [
          Text('${longDate(event.startTime)} · ${eventTimeRange(event)}'),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.close, color: Color(0xFFC9343F)),
            title: const Text('Cancel my RSVP', style: TextStyle(color: Color(0xFFC9343F))),
            onTap: () {
              Navigator.pop(sheetContext);
              _rsvp(event, false);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Event event) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this event?'),
        content: const Text("This can't be undone. Everyone who RSVP'd will lose it from their list."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE65E68)),
            child: const Text('Yes, delete'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    try {
      await _service.deleteEvent(event.id!);
      if (!mounted) return;
      // The list page shows the "Event deleted" toast
      Navigator.pop(context, 'deleted');
    } on ApiException catch (error) {
      if (mounted) _toast(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Event>(
      future: _future,
      builder: (context, snapshot) {
        final event = _event ?? snapshot.data;
        Widget body;
        Widget? bottom;
        if (snapshot.connectionState != ConnectionState.done && event == null) {
          body = const Center(child: CircularProgressIndicator(color: eventBrand));
        } else if (snapshot.hasError && event == null) {
          final error = snapshot.error;
          final gone = error is ApiException && error.statusCode == 404;
          body = Padding(
            padding: const EdgeInsets.all(16),
            child: MessageBox(
              icon: gone ? Icons.event_busy_outlined : Icons.close,
              title: gone ? "This event isn't here anymore" : "Couldn't load this event",
              message: gone ? 'The host may have deleted it. Have a look at the other events.' : error.toString(),
              buttonLabel: gone ? 'Back to events' : 'Try again',
              onPressed: gone ? () => Navigator.pop(context) : _reload,
            ),
          );
        } else {
          body = _content(event!);
          bottom = _bottomBar(event);
        }
        return Scaffold(
          backgroundColor: eventPage,
          appBar: AppBar(title: const Text('Back to events'), backgroundColor: Colors.white),
          body: body,
          bottomNavigationBar: bottom,
        );
      },
    );
  }

  Widget _content(Event event) {
    final bring = event.whatToBring.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty);
    return ListView(
      children: [
        Stack(
          children: [
            EventCover(event: event, height: 220),
            Positioned(left: 16, bottom: 16, child: DateBadge(date: event.startTime)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.themePlantName != null) ...[PlantTag(name: event.themePlantName!), const SizedBox(height: 12)],
              Text(event.name, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: eventInk)),
              const SizedBox(height: 12),
              _info(Icons.calendar_today_outlined, longDate(event.startTime)),
              _info(Icons.schedule, eventTimeRange(event)),
              _info(Icons.place_outlined, event.location),
              const Divider(height: 32),
              const Text('About this event', style: _heading),
              const SizedBox(height: 8),
              Text(event.description, style: const TextStyle(color: eventInkSoft, height: 1.5)),
              if (bring.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('What to bring', style: _heading),
                const SizedBox(height: 8),
                for (final item in bring) _info(Icons.check, item),
              ],
              const SizedBox(height: 20),
              const Text('Hosted by', style: _heading),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: eventSoft,
                    child: Text(event.host.isEmpty ? '?' : event.host[0].toUpperCase(),
                        style: const TextStyle(color: eventInk, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Text(event.host, style: const TextStyle(fontWeight: FontWeight.w800, color: eventInk)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const _heading = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: eventInk);

  Widget _info(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: eventInkSoft),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(color: eventInk))),
          ],
        ),
      );

  // The sticky bar at the bottom: what the user can do depends on who they are and when the event is
  Widget _bottomBar(Event event) {
    final isHost = widget.username != null && widget.username == event.host;
    final Widget left;
    final Widget right;
    if (isHost) {
      left = Expanded(
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Edit event'),
        ),
      );
      right = Expanded(
        child: FilledButton(
          onPressed: () => _confirmDelete(event),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE65E68), minimumSize: const Size.fromHeight(48)),
          child: const Text('Delete event'),
        ),
      );
    } else {
      String count = event.isGoing ? 'You + ${event.goingCount - 1} going' : '${event.goingCount} going';
      String label = 'RSVP';
      VoidCallback? onPressed;
      if (event.status == 'ended') {
        count = '${event.goingCount} went';
        label = 'Ended';
      } else if (event.status == 'happening') {
        count = 'Happening now';
        label = 'RSVPs closed';
      } else if (_busy) {
        label = event.isGoing ? 'Going ✓' : 'RSVP';
      } else if (!_loggedIn) {
        onPressed = _askToLogIn;
      } else if (event.isGoing) {
        label = 'Going ✓';
        onPressed = () => _askToCancel(event);
      } else {
        onPressed = () => _rsvp(event, true);
      }
      left = Expanded(child: Text(count, style: const TextStyle(fontWeight: FontWeight.w800, color: eventInk)));
      right = FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: event.isGoing ? eventBrand : eventInk,
          minimumSize: const Size(120, 48),
        ),
        child: Text(label),
      );
    }
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: isHost ? eventTint : Colors.white,
          border: const Border(top: BorderSide(color: eventInk, width: 2)),
        ),
        child: Row(children: [left, const SizedBox(width: 12), right]),
      ),
    );
  }
}

/// Title and content for the bottom sheets (log in, cancel RSVP).
class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: eventInk)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}