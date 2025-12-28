import 'package:drift/drift.dart';
import 'package:my_calendar/data/data_sources/app_database.dart';
import 'package:my_calendar/data/data_sources/tables/events_table.dart';

part 'events_dao.g.dart';

@DriftAccessor(tables: [Events])
class EventsDao extends DatabaseAccessor<AppDatabase> with _$EventsDaoMixin {
  EventsDao(super.attachedDatabase);

  // Get all events
  Stream<List<Event>> watchAllEvents() {
    return select(attachedDatabase.events).watch();
  }

  //Get events in range
  Future<List<Event>> getEventsInRange(DateTime start, DateTime end) {
    return (select(attachedDatabase.events)..where(
          (event) =>
              event.startTime.isSmallerThanValue(end) &
              event.endTime.isBiggerThanValue(start),
        ))
        .get();
  }

  Stream<List<Event>> watchEventsInRange(DateTime start, DateTime end) {
    return (select(attachedDatabase.events)..where(
          (event) =>
              event.startTime.isSmallerThanValue(end) &
              event.endTime.isBiggerThanValue(start),
        ))
        .watch();
  }

  // Get event
  Stream<Event?> watchEventById(int id) {
    return (select(
      attachedDatabase.events,
    )..where((event) => event.id.equals(id))).watchSingle();
  }

  // Create event
  Future<int> createEvent(EventsCompanion entity) {
    return into(attachedDatabase.events).insert(entity);
  }

  // Get event

  //update event
  Future<bool> updateEvent(EventsCompanion entity) {
    return update(attachedDatabase.events).replace(entity);
  }

  // Delete event
  Future<int> deleteEvent(int id) {
    return (delete(
      attachedDatabase.events,
    )..where((event) => event.id.equals(id))).go();
  }
}
