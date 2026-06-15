import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_screens.dart';
import '../models/services_setup.dart';

class ScheduleServiceScreen extends ConsumerStatefulWidget {
  const ScheduleServiceScreen({super.key});

  @override
  ConsumerState<ScheduleServiceScreen> createState() => _ScheduleServiceScreenState();
}

class _ScheduleServiceScreenState extends ConsumerState<ScheduleServiceScreen> {
  ServiceType? _selectedServiceType;
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;

  final List<int> _years = [
    DateTime.now().year,
    DateTime.now().year + 1,
  ];

  final List<String> _months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  int _getDayOfWeekInt(String dayName) {
    switch (dayName.toLowerCase()) {
      case 'monday': return DateTime.monday;
      case 'tuesday': return DateTime.tuesday;
      case 'wednesday': return DateTime.wednesday;
      case 'thursday': return DateTime.thursday;
      case 'friday': return DateTime.friday;
      case 'saturday': return DateTime.saturday;
      case 'sunday': return DateTime.sunday;
      default: return 0;
    }
  }

  List<int> _getAvailableDays() {
    if (_selectedYear == null || _selectedMonth == null || _selectedServiceType == null) {
      return [];
    }

    final int targetDayOfWeek = _getDayOfWeekInt(_selectedServiceType!.dayOfTheWeek);
    if (targetDayOfWeek == 0) return [];

    List<int> matchingDays = [];
    int daysInMonth = DateUtils.getDaysInMonth(_selectedYear!, _selectedMonth!);

    for (int i = 1; i <= daysInMonth; i++) {
      DateTime date = DateTime(_selectedYear!, _selectedMonth!, i);
      if (date.weekday == targetDayOfWeek) {
        matchingDays.add(i);
      }
    }
    return matchingDays;
  }

  @override
  Widget build(BuildContext context) {
    final serviceTypesAsync = ref.watch(serviceTypesProvider);
    final positionsAsync = ref.watch(positionsProvider);
    final availableDays = _getAvailableDays();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Schedule Service"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            serviceTypesAsync.when(
              data: (serviceTypes) {
                return DropdownButtonFormField<ServiceType>(
                  value: _selectedServiceType,
                  hint: const Text("Select Service Type"),
                  items: serviceTypes.map((type) {
                    return DropdownMenuItem<ServiceType>(
                      value: type,
                      child: Text(type.serviceName),
                    );
                  }).toList(),
                  onChanged: (ServiceType? newValue) {
                    setState(() {
                      _selectedServiceType = newValue;
                      _selectedYear = null;
                      _selectedMonth = null;
                      _selectedDay = null;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Service Type",
                    border: OutlineInputBorder(),
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text("Error loading services: $err"),
            ),
            const SizedBox(height: 20),
            if (_selectedServiceType != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Selected: ${_selectedServiceType!.serviceName}",
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text("Day: ${_selectedServiceType!.dayOfTheWeek}"),
                      Text("Time: ${_selectedServiceType!.serviceTime}"),
                    ],
                  ),
                ),
              ),
            if (_selectedServiceType != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      hint: const Text("Year"),
                      items: _years.map((year) {
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedYear = newValue;
                          _selectedDay = null; // Reset day when year changes
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: "Year",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      hint: const Text("Month"),
                      items: List.generate(12, (index) {
                        return DropdownMenuItem<int>(
                          value: index + 1,
                          child: Text(_months[index]),
                        );
                      }),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedMonth = newValue;
                          _selectedDay = null; // Reset day when month changes
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: "Month",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedDay,
                      hint: const Text("Day"),
                      items: availableDays.map((day) {
                        return DropdownMenuItem<int>(
                          value: day,
                          child: Text(day.toString()),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedDay = newValue;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: "Day",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_selectedDay != null) ...[
                const Divider(),
                const SizedBox(height: 10),
                Text("Required Positions", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                positionsAsync.when(
                  data: (positions) {
                    final filteredPositions = positions
                        .where((p) => _selectedServiceType!.positionGuids.contains(p.guid))
                        .toList();

                    if (filteredPositions.isEmpty) {
                      return const Text("No positions defined for this service type.");
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredPositions.length,
                      itemBuilder: (context, index) {
                        final pos = filteredPositions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(pos.positionName),
                            subtitle: Text("Team: ${pos.team}"),
                            trailing: const Icon(Icons.person_add_outlined),
                            onTap: () {
                              // Future: Assign member to this position for this date
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text("Error loading positions: $err"),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
