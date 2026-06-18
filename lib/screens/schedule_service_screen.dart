import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lbc_harbor_connect/services/database_service.dart';
import 'package:uuid/uuid.dart';
import 'settings_screens.dart';
import 'people_screens.dart';
import '../models/services_setup.dart';
import '../models/user_profile.dart';
import '../models/service.dart';

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
  final Map<String, Member> _assignedMembers = {};
  final ScrollController _scrollController = ScrollController();

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

  DateTime _getNextAvailableDate(String dayName) {
    int targetDay = _getDayOfWeekInt(dayName);
    if (targetDay == 0) return DateTime.now();

    DateTime now = DateTime.now();
    // Start searching from tomorrow
    DateTime date = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

    while (date.weekday != targetDay) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  Future<void> _saveSchedule() async {
    if (_selectedServiceType == null ||
        _selectedYear == null ||
        _selectedMonth == null ||
        _selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all selections before saving.")),
      );
      return;
    }

    final Map<String, String> assignments = _assignedMembers.map(
      (posGuid, member) => MapEntry(posGuid, member.guid),
    );

    final serviceInstance = ServiceInstance(
      guid: const Uuid().v4(),
      serviceTypeGuid: _selectedServiceType!.guid,
      date: DateTime(_selectedYear!, _selectedMonth!, _selectedDay!),
      assignments: assignments,
    );

    try {
      await ref.read(databaseServiceProvider).saveServiceInstance(serviceInstance);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Service scheduled successfully!")),
        );
        // Optionally reset or navigate back
        setState(() {
          _selectedServiceType = null;
          _selectedYear = null;
          _selectedMonth = null;
          _selectedDay = null;
          _assignedMembers.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving schedule: $e")),
        );
      }
    }
  }

  void _showMemberSelectionDialog(Position position) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final membersAsync = ref.watch(membersProvider);
            return AlertDialog(
              title: Text("Assign to ${position.positionName}"),
              content: SizedBox(
                width: double.maxFinite,
                child: membersAsync.when(
                  data: (members) => members.isEmpty
                      ? const Text("No members found.")
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final member = members[index];
                            return ListTile(
                              title: Text("${member.firstName} ${member.lastName}"),
                              onTap: () {
                                setState(() {
                                  _assignedMembers[position.guid] = member;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text("Error: $err"),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
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
                      _assignedMembers.clear();
                      if (newValue != null) {
                        final nextDate = _getNextAvailableDate(newValue.dayOfTheWeek);
                        _selectedYear = nextDate.year;
                        _selectedMonth = nextDate.month;
                        _selectedDay = nextDate.day;
                      } else {
                        _selectedYear = null;
                        _selectedMonth = null;
                        _selectedDay = null;
                      }
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
                    flex: 2,
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
                          _assignedMembers.clear();
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
                    flex: 3,
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
                          _assignedMembers.clear();
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
                    flex: 2,
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
                          _assignedMembers.clear();
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
                        final assignedMember = _assignedMembers[pos.guid];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(pos.positionName),
                            subtitle: Text(assignedMember != null
                                ? "Assigned: ${assignedMember.firstName} ${assignedMember.lastName}"
                                : "Team: ${pos.team}"),
                            trailing: assignedMember != null
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : const Icon(Icons.person_add_outlined),
                            onTap: () => _showMemberSelectionDialog(pos),
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
    ),
      bottomNavigationBar: _selectedDay != null
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _saveSchedule,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text("Save Schedule"),
              ),
            )
          : null,
    );
  }
}
