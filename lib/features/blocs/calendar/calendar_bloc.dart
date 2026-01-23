import 'dart:async';
import 'dart:developer';
import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_calendar/core/constants/enums/enums_calendar.dart';
import 'package:my_calendar/data/data_sources/app_database.dart';
import 'package:my_calendar/data/repos/events_repository.dart';
import 'package:my_calendar/features/blocs/calendar/calendar_event.dart';
import 'package:my_calendar/features/blocs/calendar/calendar_state.dart';
import 'package:my_calendar/core/services/notification/notification_service.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  StreamSubscription<List<Event>>? _eventsSubscription;
  final EventsRepository _eventsRepository;
  CalendarBloc(this._eventsRepository) : super(_initialState()) {
    on<CalendarInitialized>(_onCalendarInitialized);
    on<CalendarSelectedDayChanged>(_onCalendarSelectedDayChanged);
    on<CalendarFocusedDayChanged>(_onCalendarFocusedDayChanged);
    on<CalendarViewTypeChanged>(_onCalendarViewTypeChanged);
    on<CalendarEventUpdated>(_onEventsUpdated);
    on<CalendarEventUpdateOrCreated>(_onEventUpdateOrCreated);
    on<CalendarStreamFailed>(_onStreamFailed);
    on<CalendarEventDeleted>(_onEventDeleted);
  }

  Future<void> _onCalendarInitialized(
    CalendarInitialized event,
    Emitter<CalendarState> emit,
  ) async {
    emit(state.copyWith(status: CalendarStatus.loading));
    await _resubscribe(state.rangeStart, state.rangeEnd);
  }

  void _onEventsUpdated(
    CalendarEventUpdated event,
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
          (events) => add(CalendarEventUpdated(events)),
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

  FutureOr<void> _onEventUpdateOrCreated(
    CalendarEventUpdateOrCreated event,
    Emitter<CalendarState> emit,
  ) async {
    emit(state.copyWith(status: CalendarStatus.loading));
    try {
      final companion = EventsCompanion(
        id: event.id == null ? const Value.absent() : Value(event.id!),
        calendarId: Value(event.calendarId ?? 0),
        title: Value(event.title),
        description: Value(event.description),
        startTime: Value(event.startTime),
        endTime: Value(event.endTime),
        remindMinutes: Value(event.remindMinutes),
      );
      int eventId;
      if (event.id == null) {
        log('event create called');
        eventId = await _eventsRepository.createEvent(companion);
      } else {
        log('event update called');
        await _eventsRepository.updateEvent(companion);
        eventId = event.id!;
      }

      await NotificationService.instance.scheduleNotification(
        notificationId: eventId,
        title: event.title,
        body: event.description,
        scheduledTime: event.startTime,
        remindMinutes: event.remindMinutes,
      );

      emit(state.copyWith(status: CalendarStatus.successful));
    } catch (e) {
      log('event created failed:');
      log(e.toString());
      emit(state.copyWith(status: CalendarStatus.failed));
    }
  }

  FutureOr<void> _onEventDeleted(
    CalendarEventDeleted event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      await _eventsRepository.deleteEvent(event.id);
      await NotificationService.instance.cancelNotification(event.id);
      emit(state.copyWith(status: CalendarStatus.successful));
    } catch (e) {
      log('event deleted failed:');
      log(e.toString());
      emit(state.copyWith(status: CalendarStatus.failed));
    }
  }
}
