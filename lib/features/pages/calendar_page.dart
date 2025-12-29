import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_calendar/core/constants/enums/enums_calendar.dart';
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
              final result = await Navigator.of(
                context,
              ).pushNamed('/addEventRoute');
              if (result != null) {
                final data = result as Map<String, dynamic>;
                context.read<CalendarBloc>().add(
                  CalendarEventCreated(
                    title: data['title'],
                    note: data['note'],
                    startAt: data['startAt'],
                    endAt: data['endAt'],
                    remindMinutes: data['remindMinutes'],
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<CalendarBloc, CalendarState>(
        builder: (context, state) {
          if (state.status == CalendarStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else {
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
                  selectedDayPredicate: (day) =>
                      isSameDay(state.selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    context.read<CalendarBloc>().add(
                      CalendarSelectedDayChanged(selectedDay),
                    );
                  },
                  onPageChanged: (focusedDay) {
                    context.read<CalendarBloc>().add(
                      CalendarFocusedDayChanged(focusedDay),
                    );
                  },

                  eventLoader: (day) {
                    return state.events.where((event) {
                      final start = DateTime(
                        event.startTime.year,
                        event.startTime.month,
                        event.startTime.day,
                      );
                      final end = DateTime(
                        event.endTime.year,
                        event.endTime.month,
                        event.endTime.day,
                      );
                      return !day.isBefore(end) && !day.isAfter(start);
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
}
