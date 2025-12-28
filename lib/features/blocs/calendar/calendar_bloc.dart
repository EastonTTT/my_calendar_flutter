import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_calendar/core/constants/enums/enums_calendar.dart';
import 'package:my_calendar/data/data_sources/app_database.dart';
import 'package:my_calendar/data/repos/events_repository.dart';
import 'package:my_calendar/features/blocs/calendar/calendar_event.dart';
import 'package:my_calendar/features/blocs/calendar/calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  StreamSubscription<List<Event>>? _eventsSubscription;
  final EventsRepository _eventsRepository;
  CalendarBloc(this._eventsRepository) : super(_initialState()) {
    on<CalendarInitialized>(_onCalendarInitialized);
    on<CalendarSelectedDayChanged>(_onCalendarSelectedDayChanged);
    on<CalendarFocusedDayChanged>(_onCalendarFocusedDayChanged);
    on<CalendarViewTypeChanged>(_onCalendarViewTypeChanged);
    on<CalendarEventsUpdated>(_onEventsUpdated);
    on<CalendarStreamFailed>(_onStreamFailed);
  }

  Future<void> _onCalendarInitialized(
    CalendarInitialized event,
    Emitter<CalendarState> emit,
  ) async {
    emit(state.copyWith(status: CalendarStatus.loading));
    await _resubscribe(state.rangeStart, state.rangeEnd);
  }

  void _onEventsUpdated(
    CalendarEventsUpdated event,
    Emitter<CalendarState> emit,
  ) {
    emit(
      state.copyWith(events: event.events, status: CalendarStatus.successful),
    );
  }

  void _onStreamFailed(
    CalendarStreamFailed event,
    Emitter<CalendarState> emit,
  ) {
    emit(state.copyWith(status: CalendarStatus.failed));
  }

  void _onCalendarSelectedDayChanged(
    CalendarSelectedDayChanged event,
    Emitter<CalendarState> emit,
  ) {
    emit(state.copyWith(selectedDay: event.selectedDay));
  }

  Future<void> _onCalendarFocusedDayChanged(
    CalendarFocusedDayChanged event,
    Emitter<CalendarState> emit,
  ) async {
    final (start, end) = _calcRange(event.focusedDay, state.viewType);
    emit(
      state.copyWith(
        focusedDay: event.focusedDay,
        rangeStart: start,
        rangeEnd: end,
      ),
    );
    await _resubscribe(start, end);
  }

  Future<void> _onCalendarViewTypeChanged(
    CalendarViewTypeChanged event,
    Emitter<CalendarState> emit,
  ) async {
    final (start, end) = _calcRange(state.focusedDay, event.viewType);
    emit(
      state.copyWith(
        viewType: event.viewType,
        rangeStart: start,
        rangeEnd: end,
      ),
    );
    await _resubscribe(start, end);
  }

  @override
  Future<void> close() async {
    await _eventsSubscription?.cancel();
    return super.close();
  }

  static CalendarState _initialState() {
    final now = DateTime.now();
    return CalendarState(
      selectedDay: now,
      focusedDay: now,
      rangeStart: DateTime(now.year, now.month, 1),
      rangeEnd: DateTime(now.year, now.month + 1, 1),
    );
  }

  Future<void> _resubscribe(DateTime start, DateTime end) async {
    await _eventsSubscription?.cancel();
    _eventsSubscription = _eventsRepository
        .watchInRange(start, end)
        .listen(
          (events) => add(CalendarEventsUpdated(events)),
          onError: (e, _) => add(CalendarStreamFailed(e)),
        );
  }

  (DateTime, DateTime) _calcRange(
    DateTime focusedDay,
    CalendarViewType viewType,
  ) {
    switch (viewType) {
      case CalendarViewType.day:
        final start = DateTime(
          focusedDay.year,
          focusedDay.month,
          focusedDay.day,
        );
        final end = start.add(const Duration(days: 1));
        return (start, end);

      case CalendarViewType.week:
        final day = DateTime(focusedDay.year, focusedDay.month, focusedDay.day);
        final start = day.subtract(Duration(days: day.weekday - 1));
        final end = start.add(const Duration(days: 7));
        return (start, end);

      case CalendarViewType.month:
        final start = DateTime(focusedDay.year, focusedDay.month, 1);
        final end = DateTime(focusedDay.year, focusedDay.month + 1, 1);
        return (start, end);
    }
  }
}
