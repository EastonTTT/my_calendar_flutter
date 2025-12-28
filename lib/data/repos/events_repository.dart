import 'package:my_calendar/data/daos/events_dao.dart';
import 'package:my_calendar/data/data_sources/app_database.dart';

class EventsRepository {
  final EventsDao _eventsDao;

  EventsRepository({required EventsDao eventsDao}) : _eventsDao = eventsDao;

  Stream<List<Event>> watchInRange(DateTime start, DateTime end) {
    return _eventsDao.watchEventsInRange(start, end);
  }

  Future<int> createEvent(EventsCompanion event) {
    return _eventsDao.createEvent(event);
  }

  Future<bool> updateEvent(EventsCompanion event) {
    return _eventsDao.updateEvent(event);
  }

  Future<int> deleteEvent(int id) {
    return _eventsDao.deleteEvent(id);
  }
}
