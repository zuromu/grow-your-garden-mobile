import 'package:material_ui/material_ui.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';
import 'event_detail_page.dart';

/// Host an event (event == null) or Edit event. Pops with the saved Event.
class EventFormPage extends StatefulWidget {
  const EventFormPage({super.key, this.service, this.event});

  final EventService? service;
  final Event? event;

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  late final EventService _service = widget.service ?? EventService();
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.event?.name);
  late final _location = TextEditingController(text: widget.event?.location);
  late final _description = TextEditingController(text: widget.event?.description);
  late final _bring = TextEditingController(text: widget.event?.whatToBring);
  late final _cover = TextEditingController(text: widget.event?.coverPhotoUrl);

  late DateTime? _date = widget.event?.startTime.toLocal();
  late TimeOfDay? _start = widget.event == null ? null : TimeOfDay.fromDateTime(widget.event!.startTime.toLocal());
  late TimeOfDay? _end = widget.event?.endTime == null ? null : TimeOfDay.fromDateTime(widget.event!.endTime!.toLocal());
  late String? _plant = widget.event?.themePlant;
  late Future<List<PlantChoice>> _plants = _service.getPlantChoices();

  bool _dirty = false;
  bool _sending = false;
  // Errors the server sent back, shown under the matching field
  Map<String, String> _serverErrors = {};

  bool get _editing => widget.event != null;

  @override
  void dispose() {
    for (final c in [_name, _location, _description, _bring, _cover]) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime? _combine(TimeOfDay? time) {
    if (_date == null || time == null) return null;
    return DateTime(_date!.year, _date!.month, _date!.day, time.hour, time.minute);
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  // The form only has hours and minutes, so ignore seconds when checking if the start changed
  bool _startChanged(DateTime start) {
    if (!_editing) return true;
    final old = widget.event!.startTime.toLocal();
    return DateTime(old.year, old.month, old.day, old.hour, old.minute) != start;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: _editing && _date != null && _date!.isBefore(now) ? _date! : now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() { _date = picked; _dirty = true; });
  }

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (start ? _start : _end) ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
      _dirty = true;
    });
  }

  // The same rules as the website form, checked before sending
  String? _dateError() {
    final start = _combine(_start);
    if (_date == null) return 'Please pick a date.';
    if (start == null) return 'Please pick a start time.';
    if (_startChanged(start) && start.isBefore(DateTime.now())) {
      return 'This date and time has already passed. Please pick a later one.';
    }
    return _serverErrors['start_time'];
  }

  String? _endError() {
    final start = _combine(_start);
    final end = _combine(_end);
    if (start != null && end != null && !end.isAfter(start)) return 'The end time has to be after the start time.';
    return _serverErrors['end_time'];
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    final formOk = _formKey.currentState!.validate();
    if (!formOk || _dateError() != null || _endError() != null) {
      setState(() {});
      return;
    }
    final start = _combine(_start)!;
    final event = Event(
      name: _name.text.trim(),
      description: _description.text.trim(),
      location: _location.text.trim(),
      whatToBring: _bring.text.trim(),
      coverPhotoUrl: _cover.text.trim(),
      themePlant: _plant,
      startTime: start.toUtc(),
      endTime: _combine(_end)?.toUtc(),
    );
    setState(() => _sending = true);
    try {
      final saved = _editing
          ? await _service.updateEvent(widget.event!.id!, event,
              sendStartTime: _startChanged(start))
          : await _service.createEvent(event);
      if (!mounted) return;
      _dirty = false;
      Navigator.pop(context, saved);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _serverErrors = error.fieldErrors;
      });
      _formKey.currentState!.validate();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<bool> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave without saving?'),
        content: const Text('Your changes to this event will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE65E68)),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return leave == true;
  }

  InputDecoration _box(String label, {String? hint, String? helper, String? error}) => InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        errorText: error,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      );

  String? _required(String? value, String message) => (value == null || value.trim().isEmpty) ? message : null;

  @override
  Widget build(BuildContext context) {
    final dateError = _dateError();
    final endError = _endError();
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) {
          _dirty = false;
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: eventPage,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(icon: const Icon(Icons.close), tooltip: 'Close', onPressed: () => Navigator.maybePop(context)),
          title: Text(_editing ? 'Edit event' : 'Host an event'),
        ),
        body: Form(
          key: _formKey,
          // setState so PopScope knows right away that there are changes to lose
          onChanged: () {
            if (!_dirty) setState(() => _dirty = true);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: _box('Event name', hint: 'e.g. Community Seed Swap', helper: 'Keep it short, e.g. "Seed Swap".'),
                validator: (v) => _required(v, 'Please give your event a name.') ?? _serverErrors['name'],
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<PlantChoice>>(
                future: _plants,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return TextButton.icon(
                      onPressed: () => setState(() => _plants = _service.getPlantChoices()),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Couldn't load the plant list. Tap to try again."),
                    );
                  }
                  final plants = snapshot.data ?? [];
                  return DropdownButtonFormField<String?>(
                    initialValue: plants.any((p) => p.slug == _plant) ? _plant : null,
                    isExpanded: true,
                    decoration: _box('Theme plant', helper: snapshot.hasData ? null : 'Loading plants...'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No theme plant')),
                      for (final p in plants) DropdownMenuItem(value: p.slug, child: Text(p.name)),
                    ],
                    onChanged: (value) => setState(() { _plant = value; _dirty = true; }),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _location,
                textInputAction: TextInputAction.next,
                decoration: _box('Location', hint: 'e.g. Menteng Urban Farm', helper: 'Where people should go.'),
                validator: (v) => _required(v, 'Please add a location.') ?? _serverErrors['location'],
              ),
              const SizedBox(height: 16),
              _PickerField(
                label: 'Date',
                icon: Icons.calendar_today_outlined,
                value: _date == null ? 'Pick a date' : longDate(_date!),
                error: dateError,
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _PickerField(
                      label: 'Start time',
                      icon: Icons.schedule,
                      value: _start == null ? '--:--' : '${_two(_start!.hour)}:${_two(_start!.minute)}',
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerField(
                      label: 'End time (optional)',
                      icon: Icons.schedule,
                      value: _end == null ? '--:--' : '${_two(_end!.hour)}:${_two(_end!.minute)}',
                      error: endError,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                minLines: 4,
                maxLines: 8,
                keyboardType: TextInputType.multiline,
                decoration: _box('About this event', hint: 'Tell people what this event is about...'),
                validator: (v) => _required(v, 'Please tell people what the event is about.') ?? _serverErrors['description'],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bring,
                minLines: 3,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                decoration: _box('What to bring (one per line)', hint: 'Seeds in labelled envelopes\nA reusable bag'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cover,
                keyboardType: TextInputType.url,
                decoration: _box('Cover photo link',
                    hint: 'https://images.pexels.com/photos/...',
                    helper: 'Optional. Use a photo you own or a free one from Pexels.'),
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.isNotEmpty && !text.startsWith('https://')) {
                    return 'Please paste a full image link, starting with https://';
                  }
                  return _serverErrors['cover_photo_url'];
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: eventInk, width: 2)),
            ),
            child: FilledButton(
              // Disabled while sending, so a double tap can't make two events
              onPressed: _sending ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: eventBrand, minimumSize: const Size.fromHeight(48)),
              child: Text(_sending
                  ? (_editing ? 'Saving...' : 'Hosting your event...')
                  : (_editing ? 'Save changes' : 'Host event')),
            ),
          ),
        ),
      ),
    );
  }
}

/// A box that opens the date or time picker, with an error line under it like the text fields.
class _PickerField extends StatelessWidget {
  const _PickerField({required this.label, required this.icon, required this.value, required this.onTap, this.error});

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          errorMaxLines: 2,
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(value),
      ),
    );
  }
}