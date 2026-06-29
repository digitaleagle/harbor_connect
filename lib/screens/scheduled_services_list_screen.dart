import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/service.dart';
import '../services/database_service.dart';
import 'settings_screens.dart';

final scheduledServicesProvider = StreamProvider<List<ServiceInstance>>((ref) {
  return ref.watch(databaseServiceProvider).getScheduledServices();
});

class ScheduledServicesListScreen extends ConsumerWidget {
  const ScheduledServicesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledServicesAsync = ref.watch(scheduledServicesProvider);
    final serviceTypesAsync = ref.watch(serviceTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scheduled Services"),
      ),
      body: scheduledServicesAsync.when(
        data: (scheduledServices) => serviceTypesAsync.when(
          data: (serviceTypes) {
            if (scheduledServices.isEmpty) {
              return const Center(child: Text("No services scheduled."));
            }

            // Create a map for quick lookup of service type names
            final typeMap = {for (var t in serviceTypes) t.guid: t.serviceName};

            return ListView.builder(
              itemCount: scheduledServices.length,
              itemBuilder: (context, index) {
                final service = scheduledServices[index];
                final typeName = typeMap[service.serviceTypeGuid] ?? "Unknown Type";
                
                return ListTile(
                  onTap: () {
                    context.push('/schedule', extra: service);
                  },
                  leading: SizedBox(
                    width: 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('MMM').format(service.date).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          DateFormat('d').format(service.date),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  trailing: Text(
                    typeName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text("Error: $err")),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
}
