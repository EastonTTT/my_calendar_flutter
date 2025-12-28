import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_calendar/core/constants/enums/enums_calendar.dart';
import 'package:my_calendar/features/blocs/calendar/calendar_bloc.dart';
import 'package:my_calendar/features/blocs/calendar/calendar_state.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<CalendarBloc, CalendarState>(
        builder: (context, state) {
          if (state.status == CalendarStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Text(
              'viewType: ${state.viewType}\n'
              'status: ${state.status}\n'
              'selected: ${state.selectedDay}\n'
              'focused: ${state.focusedDay}\n'
              'range: ${state.rangeStart} ~ ${state.rangeEnd}\n'
              'events: ${state.events.length}\n',
            );
          }
        },
      ),
    );
  }
}
