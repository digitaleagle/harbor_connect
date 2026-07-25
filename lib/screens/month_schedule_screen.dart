import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'settings_screens.dart';
import 'scheduled_services_list_screen.dart';
import 'people_screens.dart';

class MonthScheduleScreen extends ConsumerWidget {
  const MonthScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledServicesAsync = ref.watch(scheduledServicesProvider);
    final serviceTypesAsync = ref.watch(serviceTypesProvider);
    final positionsAsync = ref.watch(positionsProvider);
    final membersAsync = ref.watch(membersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Month's Schedule"),
      ),
      body: scheduledServicesAsync.when(
        data: (scheduledServices) => serviceTypesAsync.when(
          data: (serviceTypes) => positionsAsync.when(
            data: (positions) => membersAsync.when(
              data: (members) {
                final now = DateTime.now();
                final oneMonthFromNow = now.add(const Duration(days: 30));

                final filteredServices = scheduledServices.where((service) {
                  return service.date.isAfter(now.subtract(const Duration(days: 1))) &&
                      service.date.isBefore(oneMonthFromNow);
                }).toList();

                if (filteredServices.isEmpty) {
                  return const Center(child: Text("No services scheduled for the next 30 days."));
                }

                final typeMap = {for (var t in serviceTypes) t.guid: t};
                final positionMap = {for (var p in positions) p.guid: p};
                final memberMap = {for (var m in members) m.guid: '${m.firstName} ${m.lastName}'};

                // Find all unique positions applicable to these services
                final usedPositionGuids = <String>{};
                for (var service in filteredServices) {
                  final type = typeMap[service.serviceTypeGuid];
                  if (type != null) {
                    usedPositionGuids.addAll(type.positionGuids);
                  }
                }
                
                final sortedPositionGuids = usedPositionGuids.toList()..sort((a, b) {
                  final nameA = positionMap[a]?.positionName ?? '';
                  final nameB = positionMap[b]?.positionName ?? '';
                  return nameA.compareTo(nameB);
                });

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        const DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                        const DataColumn(label: Text('Service', style: TextStyle(fontWeight: FontWeight.bold))),
                        ...sortedPositionGuids.map((guid) => DataColumn(
                          label: Text(
                            positionMap[guid]?.positionName ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )),
                      ],
                      rows: filteredServices.map((service) {
                        final type = typeMap[service.serviceTypeGuid];
                        final typeName = type?.serviceName ?? "Unknown Type";
                        
                        return DataRow(
                          onSelectChanged: (_) {
                            context.push('/schedule', extra: service);
                          },
                          cells: [
                            DataCell(Text(DateFormat('MMM d').format(service.date))),
                            DataCell(Text(typeName)),
                            ...sortedPositionGuids.map((posGuid) {
                              final memberGuid = service.assignments[posGuid];
                              final memberName = memberMap[memberGuid] ?? '';
                              return DataCell(Text(memberName));
                            }),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Error: $err")),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text("Error: $err")),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text("Error: $err")),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
}
