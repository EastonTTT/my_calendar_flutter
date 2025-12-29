import 'package:drift/drift.dart';
import 'package:my_calendar/data/data_sources/tables/calendars_table.dart';

class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get calendarId =>
      integer().references(Calendars, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get location => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  IntColumn get remindMinutes => integer().nullable()();
  TextColumn get exdate => text().nullable()();
  TextColumn get uid => text().nullable()();
  TextColumn get rrule => text().nullable()();
}
