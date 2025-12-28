import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:my_calendar/data/data_sources/tables/alarms_table.dart';
import 'package:my_calendar/data/data_sources/tables/calendars_table.dart';
import 'package:my_calendar/data/data_sources/tables/events_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Alarms, Events, Calendars])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'my_calendar_db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
