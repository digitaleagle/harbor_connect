import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lbc_harbor_connect/services/database_service.dart';
import 'package:uuid/uuid.dart';
import '../models/services_setup.dart';

class SettingsHomePage extends ConsumerStatefulWidget {
  const SettingsHomePage({super.key});

  @override
  ConsumerState<SettingsHomePage> createState() => _SettingsHomePageState();
}

class _SettingsHomePageState extends ConsumerState<SettingsHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Harbor Connect"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(onPressed: () {
              context.push('/settings/services');
            }, child: Text("Services Setup")),
            ElevatedButton(onPressed: () {
              context.push('/settings/positions');
            }, child: Text("Positions Setup")),
            ElevatedButton(onPressed: () {
              context.push('/settings/roles');
            }, child: Text("Roles Setup")),
            ElevatedButton(onPressed: () {
              context.push('/settings/teams');
            }, child: Text("Teams Setup")),
          ],
        ),
      ),
    );
  }
}

class ServiceTypeSetupScreen extends ConsumerStatefulWidget {
  const ServiceTypeSetupScreen({super.key});

  @override
  ConsumerState<ServiceTypeSetupScreen> createState() => _ServiceTypeSetupScreenState();
}

class _ServiceTypeSetupScreenState extends ConsumerState<ServiceTypeSetupScreen> {
  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(serviceTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Service Types"),
      ),
      body: servicesAsync.when(
        data: (services) => services.isEmpty
            ? const Center(child: Text("No services found. Tap + to add one."))
            : ListView.builder(
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return ListTile(
                    title: Text(service.serviceName),
                    subtitle: Text("${service.dayOfTheWeek} at ${service.serviceTime}"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/settings/services/add', extra: service);
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/settings/services/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ServiceTypeDetailsScreen extends ConsumerStatefulWidget {
  final ServiceType? serviceType;
  const ServiceTypeDetailsScreen({this.serviceType, super.key});

  @override
  ConsumerState<ServiceTypeDetailsScreen> createState() => _ServiceTypeDetailsScreenState();
}

class _ServiceTypeDetailsScreenState extends ConsumerState<ServiceTypeDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _timeController;
  String? _selectedDay;
  final Set<String> _selectedPositionGuids = {};

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.serviceType?.serviceName ?? '');
    _timeController = TextEditingController(text: widget.serviceType?.serviceTime ?? '');
    _selectedDay = widget.serviceType?.dayOfTheWeek;
    if (widget.serviceType?.positionGuids != null) {
      _selectedPositionGuids.addAll(widget.serviceType!.positionGuids);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final positionsAsync = ref.watch(positionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.serviceType == null ? "Add Service Type" : "Edit Service Type")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Service Name"),
                validator: (value) => value == null || value.isEmpty ? "Required" : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedDay,
                decoration: const InputDecoration(labelText: "Day of the Week"),
                items: _daysOfWeek.map((String day) {
                  return DropdownMenuItem<String>(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDay = newValue;
                  });
                },
                validator: (value) => value == null || value.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(labelText: "Service Time"),
                validator: (value) => value == null || value.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              const Text("Applicable Positions:", style: TextStyle(fontWeight: FontWeight.bold)),
              positionsAsync.when(
                data: (positions) => Column(
                  children: positions.map((pos) {
                    return CheckboxListTile(
                      title: Text(pos.positionName),
                      subtitle: Text(pos.team),
                      value: _selectedPositionGuids.contains(pos.guid),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedPositionGuids.add(pos.guid);
                          } else {
                            _selectedPositionGuids.remove(pos.guid);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text("Error loading positions: $err"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final newService = ServiceType(
                      guid: widget.serviceType?.guid,
                      serviceName: _nameController.text,
                      dayOfTheWeek: _selectedDay!,
                      serviceTime: _timeController.text,
                      positionGuids: _selectedPositionGuids.toList(),
                    );
                    await ref.read(databaseServiceProvider).saveServiceType(newService);
                    if (context.mounted) context.pop();
                  }
                },
                child: const Text("Save Service"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final serviceTypesProvider = StreamProvider<List<ServiceType>>((ref) {
  return ref.watch(databaseServiceProvider).getServiceTypes();
});

class PositionSetupScreen extends ConsumerStatefulWidget {
  const PositionSetupScreen({super.key});

  @override
  ConsumerState<PositionSetupScreen> createState() => _PositionSetupScreenState();
}

class _PositionSetupScreenState extends ConsumerState<PositionSetupScreen> {
  @override
  Widget build(BuildContext context) {
    final positionsAsync = ref.watch(positionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Positions Setup"),
      ),
      body: positionsAsync.when(
        data: (positions) => positions.isEmpty
            ? const Center(child: Text("No positions found. Tap + to add one."))
            : ListView.builder(
                itemCount: positions.length,
                itemBuilder: (context, index) {
                  final position = positions[index];
                  return ListTile(
                    title: Text(position.positionName),
                    subtitle: Text("Team: ${position.team}"),
                    trailing: const Icon(Icons.chevron_right),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/settings/positions/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddPositionScreen extends ConsumerStatefulWidget {
  const AddPositionScreen({super.key});

  @override
  ConsumerState<AddPositionScreen> createState() => _AddPositionScreenState();
}

class _AddPositionScreenState extends ConsumerState<AddPositionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _teamController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _teamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Position")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Position Name"),
                validator: (value) => value == null || value.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _teamController,
                decoration: const InputDecoration(labelText: "Team"),
                validator: (value) => value == null || value.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final newPosition = Position(
                      guid: const Uuid().v4(),
                      positionName: _nameController.text,
                      team: _teamController.text,
                    );
                    await ref.read(databaseServiceProvider).savePosition(newPosition);
                    if (context.mounted) context.pop();
                  }
                },
                child: const Text("Save Position"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final positionsProvider = StreamProvider<List<Position>>((ref) {
  return ref.watch(databaseServiceProvider).getPositions();
});

class RolesScreen extends ConsumerWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(rolesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Roles"),
      ),
      body: rolesAsync.when(
        data: (roles) => roles.isEmpty
            ? const Center(child: Text("No roles found. Tap + to add one."))
            : ListView.builder(
                itemCount: roles.length,
                itemBuilder: (context, index) {
                  final role = roles[index];
                  return ListTile(
                    title: Text(role.roleName),
                    subtitle: Text("Editor: ${role.isServiceEditor}, Manager: ${role.isMemberManager}"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/settings/roles/detail', extra: role);
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/settings/roles/detail');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class RoleDetailScreen extends ConsumerStatefulWidget {
  final Role? role;
  const RoleDetailScreen({this.role, super.key});

  @override
  ConsumerState<RoleDetailScreen> createState() => _RoleDetailScreenState();
}

class _RoleDetailScreenState extends ConsumerState<RoleDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late bool _isServiceEditor;
  late bool _isMemberManager;
  late bool _isSuperuser;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role?.roleName ?? '');
    _isServiceEditor = widget.role?.isServiceEditor ?? false;
    _isMemberManager = widget.role?.isMemberManager ?? false;
    _isSuperuser = widget.role?.isSuperuser ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.role == null ? "Add Role" : "Edit Role"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Role Name"),
                validator: (value) => value == null || value.isEmpty ? "Required" : null,
              ),
              SwitchListTile(
                title: const Text("Service Editor"),
                value: _isServiceEditor,
                onChanged: (val) => setState(() => _isServiceEditor = val),
              ),
              SwitchListTile(
                title: const Text("Member Manager"),
                value: _isMemberManager,
                onChanged: (val) => setState(() => _isMemberManager = val),
              ),
              SwitchListTile(
                title: const Text("Superuser"),
                value: _isSuperuser,
                onChanged: (val) => setState(() => _isSuperuser = val),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final newRole = Role(
                      guid: widget.role?.guid ?? const Uuid().v4(),
                      roleName: _nameController.text,
                      isServiceEditor: _isServiceEditor,
                      isMemberManager: _isMemberManager,
                      isSuperuser: _isSuperuser,
                    );
                    await ref.read(databaseServiceProvider).saveRole(newRole);
                    if (context.mounted) context.pop();
                  }
                },
                child: const Text("Save Role"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final rolesProvider = StreamProvider<List<Role>>((ref) {
  return ref.watch(databaseServiceProvider).getRoles();
});

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Teams"),
      ),
      body: teamsAsync.when(
        data: (teams) => teams.isEmpty
            ? const Center(child: Text("No teams found. Tap + to add one."))
            : ListView.builder(
                itemCount: teams.length,
                itemBuilder: (context, index) {
                  final team = teams[index];
                  return ListTile(
                    title: Text(team.name),
                    subtitle: Text(team.notes),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/settings/teams/detail', extra: team);
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/settings/teams/detail');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TeamDetailScreen extends ConsumerStatefulWidget {
  final Team? team;
  const TeamDetailScreen({this.team, super.key});

  @override
  ConsumerState<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends ConsumerState<TeamDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.team?.name ?? '');
    _notesController = TextEditingController(text: widget.team?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team == null ? "Add Team" : "Edit Team"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Team Name"),
                validator: (value) => value == null || value.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: "Notes"),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final newTeam = Team(
                      guid: widget.team?.guid ?? const Uuid().v4(),
                      name: _nameController.text,
                      notes: _notesController.text,
                    );
                    await ref.read(databaseServiceProvider).saveTeam(newTeam);
                    if (context.mounted) context.pop();
                  }
                },
                child: const Text("Save Team"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final teamsProvider = StreamProvider<List<Team>>((ref) {
  return ref.watch(databaseServiceProvider).getTeams();
});
