import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:my_calendar/core/constants/enums/enums_calendar.dart';
import 'package:my_calendar/core/constants/routes/calendar_page_routes.dart';
import 'package:my_calendar/data/data_sources/app_database.dart';
import 'package:my_calendar/features/blocs/calendar/calendar_bloc.dart';
import 'package:my_calendar/features/blocs/calendar/calendar_event.dart';
import 'package:my_calendar/features/blocs/calendar/calendar_state.dart';
import 'package:my_calendar/features/widgets/calendar_view_type_switcher.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await _showAddEventPage(context);
            },
          ),
        ],
      ),
      body: BlocBuilder<CalendarBloc, CalendarState>(
        builder: (context, state) {
          if (state.status == CalendarStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            final selectedDay = state.selectedDay ?? state.focusedDay;

            final selectedEvents = state.events.where((event) {
              final d = DateUtils.dateOnly(selectedDay);
              final s = DateUtils.dateOnly(event.startTime);
              final e = DateUtils.dateOnly(event.endTime);
              return !d.isBefore(s) && !d.isAfter(e); // 包含边界：同一天/跨天都能命中
            }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
            final (weekStart, weekEnd) = _weekRange(selectedDay);

            final weekEvents = state.events.where((event) {
              return event.startTime.isBefore(weekEnd) &&
                  event.endTime.isAfter(weekStart);
            }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

            final Map<DateTime, List<Event>> weekGrouped = {};
            for (int i = 0; i < 7; i++) {
              final day = DateTime(
                weekStart.year,
                weekStart.month,
                weekStart.day + i,
              );
              final list = weekEvents.where((e) => _hitsDay(e, day)).toList()
                ..sort((a, b) => a.startTime.compareTo(b.startTime));
              weekGrouped[day] = list;
            }

            return Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                CalendarViewTypeSwitcher(
                  onViewTypeChanged: (CalendarViewType type) {
                    context.read<CalendarBloc>().add(
                      CalendarViewTypeChanged(type),
                    );
                  },
                  type: state.viewType,
                ),
                const SizedBox(height: 8),
                TableCalendar(
                  focusedDay: state.focusedDay,
                  firstDay: DateTime(2000, 1, 1),
                  lastDay: DateTime(2100, 1, 1),
                  calendarFormat: _calendarFormatFromViewType(state.viewType),
                  selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    context.read<CalendarBloc>().add(
                      CalendarSelectedDayChanged(selectedDay),
                    );
                    context.read<CalendarBloc>().add(
                      CalendarFocusedDayChanged(focusedDay),
                    );
                  },
                  onPageChanged: (focusedDay) {
                    context.read<CalendarBloc>().add(
                      CalendarFocusedDayChanged(focusedDay),
                    );
                  },

                  eventLoader: (day) {
                    final d = DateUtils.dateOnly(day);
                    return state.events.where((event) {
                      final s = DateUtils.dateOnly(event.startTime);
                      final e = DateUtils.dateOnly(event.endTime);
                      return !d.isBefore(s) && !d.isAfter(e); // inclusive
                    }).toList();
                  },

                  headerStyle: HeaderStyle(
                    titleTextStyle: const TextStyle(fontSize: 16),
                    formatButtonVisible: false,
                    leftChevronIcon: const Icon(Icons.chevron_left),
                    rightChevronIcon: const Icon(Icons.chevron_right),
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(),
                  ),
                ),

                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'All events: ${state.events.length} | Selected: ${selectedEvents.length}',
                  ),
                ),
                Expanded(
                  child: state.viewType == CalendarViewType.week
                      ? _buildWeekAgenda(context, weekGrouped)
                      : _buildSelectedDayList(context, selectedEvents),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  CalendarFormat _calendarFormatFromViewType(CalendarViewType viewType) {
    switch (viewType) {
      case CalendarViewType.week:
        return CalendarFormat.week;
      case CalendarViewType.month:
        return CalendarFormat.month;
      case CalendarViewType.day:
        // No day view
        return CalendarFormat.week;
    }
  }

  (DateTime, DateTime) _weekRange(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final start = d.subtract(Duration(days: d.weekday - 1)); // Monday
    final end = start.add(const Duration(days: 7)); // exclusive
    return (start, end);
  }

  bool _hitsDay(Event event, DateTime day) {
    final d = DateUtils.dateOnly(day);
    final s = DateUtils.dateOnly(event.startTime);
    final e = DateUtils.dateOnly(event.endTime);
    return !d.isBefore(s) && !d.isAfter(e); // inclusive
  }

  Future<void> _showAddEventPage(BuildContext context, {Event? event}) async {
    final result = await Navigator.of(
      context,
    ).pushNamed(addOrUpdateEventRoute, arguments: event);
    if (result != null) {
      final data = result as Map<String, dynamic>;
      log('get data from addOrUpdateEventRoute:');
      log(data.toString());
      context.read<CalendarBloc>().add(
        CalendarEventUpdateOrCreated(
          id: data['id'],
          calendarId: data['calendarId'],
          title: data['title'],
          description: data['description'],
          startTime: data['startTime'],
          endTime: data['endTime'],
          remindMinutes: data['remindMinutes'],
        ),
      );
    }
  }

  Widget _buildSelectedDayList(BuildContext context, List<Event> events) {
    if (events.isEmpty) {
      return const Center(child: Text('No events'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: events.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final event = events[index];
        final start = TimeOfDay.fromDateTime(event.startTime).format(context);
        final end = TimeOfDay.fromDateTime(event.endTime).format(context);

        return Slidable(
          key: ValueKey(event.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (_) {
                  context.read<CalendarBloc>().add(
                    CalendarEventDeleted(event.id),
                  );
                },
                backgroundColor: Colors.red,
                icon: Icons.delete,
                label: 'Delete',
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(event.title),
            subtitle: Text('$start - $end'),
            onTap: () async {
              await _showAddEventPage(context, event: event);
            },
          ),
        );
      },
    );
  }

  Widget _buildWeekAgenda(
    BuildContext context,
    Map<DateTime, List<Event>> grouped,
  ) {
    // 只渲染有事件的天（更干净），你也可以改成 7 天都展示
    final daysWithEvents = grouped.entries
        .where((e) => e.value.isNotEmpty)
        .toList();

    if (daysWithEvents.isEmpty) {
      return const Center(child: Text('No events this week'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: daysWithEvents.length,
      itemBuilder: (context, index) {
        final entry = daysWithEvents[index];
        final day = entry.key;
        final events = entry.value;

        final title = '${day.month}/${day.day}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...events.map((event) {
              final start = TimeOfDay.fromDateTime(
                event.startTime,
              ).format(context);
              final end = TimeOfDay.fromDateTime(event.endTime).format(context);

              return Slidable(
                key: ValueKey('week-${event.id}-${day.toIso8601String()}'),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) {
                        context.read<CalendarBloc>().add(
                          CalendarEventDeleted(event.id),
                        );
                      },
                      backgroundColor: Colors.red,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(event.title),
                  subtitle: Text('$start - $end'),
                  onTap: () async {
                    await _showAddEventPage(context, event: event);
                  },
                ),
              );
            }),
            const Divider(height: 16),
          ],
        );
      },
    );
  }
}
