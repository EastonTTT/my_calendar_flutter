import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:my_calendar/data/data_sources/app_database.dart';

class AddOrUpdateEventPage extends StatefulWidget {
  final Event? initialEvent;
  const AddOrUpdateEventPage({super.key, this.initialEvent});

  @override
  State<AddOrUpdateEventPage> createState() => _AddOrUpdateEventPageState();
}

class _AddOrUpdateEventPageState extends State<AddOrUpdateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  int _remindMinutes = 0;
  bool get _isEditing => widget.initialEvent != null;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  DateTime _combine(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  void _onSave() {
    log('onSave called');
    if (!_formKey.currentState!.validate()) return;

    final startAt = _combine(_selectedDate, _startTime);
    final endAt = _combine(_selectedDate, _endTime);

    if (endAt.isBefore(startAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final result = {
      'id': _isEditing ? widget.initialEvent!.id : null,
      'title': _titleCtrl.text.trim(),
      'description': _noteCtrl.text.trim(),
      'startTime': startAt,
      'endTime': endAt,
      'remindMinutes': _remindMinutes,
      'calendarId': 0,
      'isUpdated': _isEditing,
    };

    Navigator.pop(context, result);
  }

  @override
  void initState() {
    log('AddOrUpdateEventPage initState');
    log(widget.initialEvent.toString());
    super.initState();
    if (_isEditing) {
      final event = widget.initialEvent!;
      _titleCtrl.text = event.title;
      _noteCtrl.text = event.description ?? '';
      _selectedDate = event.startTime;
      _startTime = TimeOfDay.fromDateTime(event.startTime);
      _endTime = TimeOfDay.fromDateTime(event.endTime);
      _remindMinutes = event.remindMinutes ?? 0;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editing Your Task'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(radius: 14),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Title'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText: 'Enter title here.',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),

              const SizedBox(height: 14),
              const Text('Note'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  hintText: 'Enter note here.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
              ),

              const SizedBox(height: 14),
              const Text('Date'),
              const SizedBox(height: 6),
              _ReadOnlyField(
                text: _fmtDate(_selectedDate),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000, 1, 1),
                    lastDate: DateTime(2100, 1, 1),
                    initialDate: _selectedDate,
                  );
                  if (picked == null) {
                    return;
                  }
                  setState(() {
                    _selectedDate = picked;
                  });
                },
              ),

              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Time'),
                        const SizedBox(height: 6),
                        _ReadOnlyField(
                          text: _fmtTime(_startTime),
                          trailing: const Icon(Icons.access_time),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _startTime,
                            );
                            if (picked == null) {
                              return;
                            }
                            setState(() {
                              _startTime = picked;
                              final startDt = _combine(
                                _selectedDate,
                                _startTime,
                              );
                              final endDt = _combine(_selectedDate, _endTime);
                              if (endDt.isBefore(startDt)) {
                                final newEnd = startDt.add(
                                  const Duration(minutes: 30),
                                );
                                _endTime = TimeOfDay(
                                  hour: newEnd.hour,
                                  minute: newEnd.minute,
                                );
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Time'),
                        const SizedBox(height: 6),
                        _ReadOnlyField(
                          text: _fmtTime(_endTime),
                          trailing: const Icon(Icons.access_time),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _endTime,
                            );
                            if (picked == null) return;

                            final startDt = _combine(_selectedDate, _startTime);
                            final pickedDt = _combine(_selectedDate, picked);

                            // 结束时间不能早于开始时间
                            if (pickedDt.isBefore(startDt)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'End time cannot be earlier than start time',
                                  ),
                                ),
                              );
                              return;
                            }

                            setState(() => _endTime = picked);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Text('Remind'),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                initialValue: _remindMinutes,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [0, 5, 10, 15, 30, 60]
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(
                          m == 0 ? 'At time of event' : '$m minutes early',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _remindMinutes = v);
                },
              ),

              const SizedBox(height: 14),
              const Text('Repeat'),
              const SizedBox(height: 6),
              const _ReadOnlyField(
                text: 'None',
                trailing: Icon(Icons.keyboard_arrow_down),
              ),

              const SizedBox(height: 14),
              const Text('Color'),
              const SizedBox(height: 8),
              Row(
                children: const [
                  _ColorDot(selected: true),
                  SizedBox(width: 10),
                  _ColorDot(selected: false),
                  SizedBox(width: 10),
                  _ColorDot(selected: false),
                ],
              ),

              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    _onSave();
                  },
                  child: Text(_isEditing ? 'Update Event' : 'Create Event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String text;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ReadOnlyField({required this.text, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: const InputDecoration(border: OutlineInputBorder()),
          child: Row(
            children: [
              Expanded(child: Text(text)),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final bool selected;
  const _ColorDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(width: selected ? 3 : 1),
      ),
    );
  }
}
