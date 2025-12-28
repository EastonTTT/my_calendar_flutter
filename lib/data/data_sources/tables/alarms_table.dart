import 'package:drift/drift.dart';
import 'package:my_calendar/data/data_sources/tables/events_table.dart';

class Alarms extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId =>
      integer().references(Events, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get triggerAt => dateTime().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
}
