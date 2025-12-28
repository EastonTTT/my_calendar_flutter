import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_calendar/data/daos/events_dao.dart';
import 'package:my_calendar/data/data_sources/app_database.dart';
import 'package:my_calendar/data/repos/events_repository.dart';
import 'package:my_calendar/features/blocs/calendar/calendar_bloc.dart';
import 'package:my_calendar/features/blocs/calendar/calendar_event.dart';
import 'package:my_calendar/features/pages/calendar_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final AppDatabase db = AppDatabase();
  final eventsDao = EventsDao(db);
  final eventsRepository = EventsRepository(eventsDao: eventsDao);
  runApp(MyApp(eventsRepository: eventsRepository));
}

class MyApp extends StatelessWidget {
  final EventsRepository eventsRepository;
  const MyApp({super.key, required this.eventsRepository});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: eventsRepository,
      child: BlocProvider(
        create: (context) =>
            CalendarBloc(context.read<EventsRepository>())
              ..add(const CalendarInitialized()),
        child: MaterialApp(title: 'My Calendar', home: const CalendarPage()),
      ),
    );
  }
}
