import 'package:equatable/equatable.dart';
import 'package:my_calendar/core/constants/enums/enums_calendar.dart';
import 'package:my_calendar/data/data_sources/app_database.dart';

abstract class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

class CalendarInitialized extends CalendarEvent {
  const CalendarInitialized();
}

class CalendarSelectedDayChanged extends CalendarEvent {
  final DateTime selectedDay;
  const CalendarSelectedDayChanged(this.selectedDay);

  @override
  List<Object?> get props => [selectedDay];
}

class CalendarFocusedDayChanged extends CalendarEvent {
  final DateTime focusedDay;
  const CalendarFocusedDayChanged(this.focusedDay);

  @override
  List<Object?> get props => [focusedDay];
}

class CalendarViewTypeChanged extends CalendarEvent {
  final CalendarViewType viewType;
  const CalendarViewTypeChanged(this.viewType);

  @override
  List<Object?> get props => [viewType];
}

class CalendarEventUpdateOrCreated extends CalendarEvent {
  final int? id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final int remindMinutes;
  final int calendarId;
  const CalendarEventUpdateOrCreated({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.remindMinutes,
    required this.calendarId,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    startTime,
    endTime,
    remindMinutes,
  ];
}

class CalendarEventUpdated extends CalendarEvent {
  final List<Event> events;
  const CalendarEventUpdated(this.events);

  @override
  List<Object?> get props => [events];
}

class CalendarEventDeleted extends CalendarEvent {
  final int id;
  const CalendarEventDeleted(this.id);

  @override
  List<Object?> get props => [id];
}

class CalendarStreamFailed extends CalendarEvent {
  final Object error;
  const CalendarStreamFailed(this.error);

  @override
  List<Object?> get props => [error];
}
