// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lbc_harbor_connect/models/services_setup.dart';
import '../models/user_profile.dart';

final databaseServiceProvider = Provider((ref) => DatabaseService());

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save or overwrite a user profile inside the 'users' collection
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _db
          .collection('users')
          .doc(profile.uid) // Use the user's explicit UID as the Document ID
          .set(profile.toJson(), SetOptions(merge: true)); // Merge prevents wiping existing fields
    } catch (e) {
      throw Exception('Database Write Failure: $e');
    }
  }

  // Fetch a user profile once as a Future
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromJson(doc.data()!);
  }

  // Save or overwrite a service type inside the 'church-services' collection
  Future<void> saveServiceType(ServiceType service) async {
    try {
      await _db
          .collection('church-services-type')
          .doc(service.guid) // Use the service's explicit GUID as the Document ID
          .set(service.toJson(), SetOptions(merge: true)); // Merge prevents wiping existing fields
    } catch (e) {
      throw Exception('Database Write Failure: $e');
    }
  }

  // Fetch a service type once as a Future
  Future<ServiceType?> getServiceType(String uid) async {
    final doc = await _db.collection('church-services-type').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return ServiceType.fromJson(doc.data()!);
  }

  // Stream all service types
  Stream<List<ServiceType>> getServiceTypes() {
    return _db.collection('church-services-type').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceType.fromJson(doc.data()))
          .toList();
    });
  }

  // Save or overwrite a position inside the 'positions' collection
  Future<void> savePosition(Position position) async {
    try {
      await _db
          .collection('positions')
          .doc(position.guid)
          .set(position.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Database Write Failure: $e');
    }
  }

  // Stream all positions
  Stream<List<Position>> getPositions() {
    return _db.collection('positions').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Position.fromJson(doc.data()))
          .toList();
    });
  }

  // Save or overwrite a member inside the 'members' collection
  Future<void> saveMember(Member member) async {
    try {
      await _db
          .collection('members')
          .doc(member.guid)
          .set(member.toJson(), SetOptions(merge: true));

      if(member.userUid != null && member.userUid!.isNotEmpty) {
        // Build permissions list
        List<String> permissions = [];
        for(var roleGuid in member.roleGuids) {
          var role = await getRole(roleGuid);
          if(role != null) {
            var roleJson = role.toJson();
            for(var key in roleJson.keys) {
              if(key != 'guid' && key != 'roleName' && roleJson[key] == true) {
                String permission = key;
                if (permission.startsWith('is') && permission.length > 2) {
                  permission = permission.substring(2, 3).toLowerCase() + permission.substring(3);
                }
                if(!permissions.contains(permission)) {
                  permissions.add(permission);
                }
              }
            }
          }
        }
        Map<String, dynamic> securityObj = {
          "guid": member.guid,
          // just for ease troubleshooting from the firebase console
          "name": "${member.firstName} ${member.lastName}",
          "permissions": permissions,
        };
        await _db
            .collection('memberSecurity')
            .doc(member.userUid)
            .set(securityObj, SetOptions(merge: false));
      }
    } catch (e) {
      throw Exception('Database Write Failure: $e');
    }
  }

  // Stream all members
  Stream<List<Member>> getMembers() {
    return _db.collection('members').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Member.fromJson(doc.data()))
          .toList();
    });
  }

  // Save or overwrite a role inside the 'roles' collection
  Future<void> saveRole(Role role) async {
    try {
      await _db
          .collection('roles')
          .doc(role.guid)
          .set(role.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Database Write Failure: $e');
    }
  }

  // Stream all roles
  Stream<List<Role>> getRoles() {
    return _db.collection('roles').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Role.fromJson(doc.data()))
          .toList();
    });
  }

  Future<Role?> getRole(String guid) async {
    final doc = await _db.collection('roles').doc(guid).get();
    if (!doc.exists || doc.data() == null) return null;
    return Role.fromJson(doc.data()!);
  }

}
