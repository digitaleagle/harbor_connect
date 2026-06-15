import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/services_setup.dart';
import '../services/database_service.dart';

final membersProvider = StreamProvider<List<Member>>((ref) {
  return ref.watch(databaseServiceProvider).getMembers();
});

final rolesProvider = StreamProvider<List<Role>>((ref) {
  return ref.watch(databaseServiceProvider).getRoles();
});

class PeopleSearchPage extends ConsumerWidget {
  const PeopleSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("People Search"),
      ),
      body: membersAsync.when(
        data: (members) => members.isEmpty
            ? const Center(child: Text("No members found."))
            : ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    title: Text('${member.firstName} ${member.lastName}'),
                    subtitle: Text(member.userUid ?? 'No User ID'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/people/details', extra: member);
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.startsWith('/people/import')) {
      currentIndex = 1;
    } else if (location.startsWith('/people/details')) {
      currentIndex = 2;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) context.go('/people/search');
          if (index == 1) context.go('/people/import');
          if (index == 2) context.go('/people/details');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.upload_file), label: 'Import'),
          BottomNavigationBarItem(icon: Icon(Icons.person_add), label: 'Add Member'),
        ],
      ),
    );
  }
}

class ImportPeopleScreen extends StatefulWidget {
  const ImportPeopleScreen({super.key});

  @override
  State<ImportPeopleScreen> createState() => _ImportPeopleScreenState();
}

class _ImportPeopleScreenState extends State<ImportPeopleScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleImport() {
    final String enteredText = _textController.text.trim();

    if (enteredText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text before importing.')),
      );
      return;
    }

    print('Importing data: $enteredText');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Data'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Paste or type your data here...',
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleImport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Import',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MemberDetailsScreen extends ConsumerStatefulWidget {
  final Member? member;
  const MemberDetailsScreen({this.member, super.key});

  @override
  ConsumerState<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends ConsumerState<MemberDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _familyGuidController;
  late TextEditingController _userUidController;
  List<String> _selectedRoleGuids = [];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.member?.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.member?.lastName ?? '');
    _familyGuidController = TextEditingController(text: widget.member?.familyGuid ?? '');
    _userUidController = TextEditingController(text: widget.member?.userUid ?? '');
    _selectedRoleGuids = List.from(widget.member?.roleGuids ?? []);
  }

  @override
  void didUpdateWidget(MemberDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.member != oldWidget.member) {
      _firstNameController.text = widget.member?.firstName ?? '';
      _lastNameController.text = widget.member?.lastName ?? '';
      _familyGuidController.text = widget.member?.familyGuid ?? '';
      _userUidController.text = widget.member?.userUid ?? '';
      _selectedRoleGuids = List.from(widget.member?.roleGuids ?? []);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _familyGuidController.dispose();
    _userUidController.dispose();
    super.dispose();
  }

  Future<void> _saveMember() async {
    if (_formKey.currentState!.validate()) {
      final member = Member(
        guid: widget.member?.guid ?? const Uuid().v4(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        familyGuid: _familyGuidController.text.trim().isEmpty ? null : _familyGuidController.text.trim(),
        userUid: _userUidController.text.trim().isEmpty ? null : _userUidController.text.trim(),
        roleGuids: _selectedRoleGuids,
      );

      try {
        await ref.read(databaseServiceProvider).saveMember(member);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member saved successfully')),
          );
          if (widget.member == null) {
            _firstNameController.clear();
            _lastNameController.clear();
            _familyGuidController.clear();
            _userUidController.clear();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save member: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member == null ? 'Add Member' : 'Member Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter first name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter last name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _familyGuidController,
                decoration: const InputDecoration(labelText: 'Family GUID (Optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _userUidController,
                decoration: const InputDecoration(labelText: 'User UID (Optional)'),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Roles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              ref.watch(rolesProvider).when(
                    data: (roles) {
                      if (roles.isEmpty) return const Text("No roles defined.");
                      return Column(
                        children: roles.map((role) {
                          return CheckboxListTile(
                            title: Text(role.roleName),
                            value: _selectedRoleGuids.contains(role.guid),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedRoleGuids.add(role.guid);
                                } else {
                                  _selectedRoleGuids.remove(role.guid);
                                }
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (err, stack) => Text("Error loading roles: $err"),
                  ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveMember,
                  child: const Text('Save Member'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
