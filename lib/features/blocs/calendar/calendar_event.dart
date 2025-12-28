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

class CalendarEventsUpdated extends CalendarEvent {
  final List<Event> events;
  const CalendarEventsUpdated(this.events);

  @override
  List<Object?> get props => [events];
}

class CalendarStreamFailed extends CalendarEvent {
  final Object error;
  const CalendarStreamFailed(this.error);

  @override
  List<Object?> get props => [error];
}
