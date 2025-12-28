import 'package:equatable/equatable.dart';
import 'package:my_calendar/core/constants/enums/enums_calendar.dart';
import 'package:my_calendar/data/data_sources/app_database.dart';

class CalendarState extends Equatable {
  final CalendarViewType viewType;
  final CalendarStatus status;
  final DateTime selectedDay;
  final DateTime focusedDay;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final List<Event> events;

  const CalendarState({
    this.viewType = CalendarViewType.month,
    this.status = CalendarStatus.initial,
    required this.selectedDay,
    required this.focusedDay,
    required this.rangeStart,
    required this.rangeEnd,
    this.events = const [],
  });

  CalendarState copyWith({
    CalendarViewType? viewType,
    CalendarStatus? status,
    DateTime? selectedDay,
    DateTime? focusedDay,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    List<Event>? events,
  }) {
    return CalendarState(
      viewType: viewType ?? this.viewType,
      status: status ?? this.status,
      selectedDay: selectedDay ?? this.selectedDay,
      focusedDay: focusedDay ?? this.focusedDay,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
      events: events ?? this.events,
    );
  }

  @override
  List<Object?> get props => [
    viewType,
    status,
    selectedDay,
    focusedDay,
    rangeStart,
    rangeEnd,
    events,
  ];
}
