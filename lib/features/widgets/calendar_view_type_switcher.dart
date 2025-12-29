import 'package:flutter/material.dart';
import 'package:my_calendar/core/constants/enums/enums_calendar.dart';

typedef ViewTypeSwitchCallback = void Function(CalendarViewType);

class CalendarViewTypeSwitcher extends StatelessWidget {
  final ViewTypeSwitchCallback onViewTypeChanged;
  final CalendarViewType type;
  const CalendarViewTypeSwitcher({
    super.key,
    required this.onViewTypeChanged,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final options = <CalendarViewType>[
      CalendarViewType.week,
      CalendarViewType.month,
    ];

    String getLabel(CalendarViewType viewType) {
      switch (viewType) {
        case CalendarViewType.week:
          return 'Week';
        case CalendarViewType.month:
          return 'Month';
        case CalendarViewType.day:
          throw UnimplementedError();
      }
    }

    return SegmentedButton<CalendarViewType>(
      segments: [
        for (final option in options)
          ButtonSegment(value: option, label: Text(getLabel(option))),
      ],
      selected: <CalendarViewType>{type},
      onSelectionChanged: (set) => onViewTypeChanged(set.first),
    );
  }
}
