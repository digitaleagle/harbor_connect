import 'package:lbc_harbor_connect/models/service.dart';
import 'package:lbc_harbor_connect/models/user_profile.dart';
import 'package:riverpod/src/framework.dart';

class NextUpList {
  List<NextUpItem> list = [];
  var isLoading = true;
  var _pointers = Map<String, NextUpItem>();

  void load(AsyncValue<List<Member>> membersAsync, AsyncValue<List<ServiceInstance>> scheduledServicesAsync) {
    if(!scheduledServicesAsync.hasValue) {
      isLoading = true;
      return;
    }
    if(!membersAsync.hasValue) {
      isLoading = true;
      return;
    }
    isLoading = false;
    var members = Map<String, Member>();
    for(var member in membersAsync.value!) {
      members[member.guid] = member;
      var nextUpItem = NextUpItem(member);
      list.add(nextUpItem);
      _pointers[member.guid] = nextUpItem;
    };
    var services = scheduledServicesAsync.value;
    for(var service in services!) {
      print(service.date);
      for(var assignment in service.assignments.entries) {
        print("  - ${assignment.value}");
        print("    > ${members[assignment.value]!.firstName} ${members[assignment.value]!.lastName}");
        var nextUpItem = NextUpItem(members[assignment.value]!, lastServedDate: service.date, lastServedService: service);
        add(nextUpItem);
      }
    }

    print("\n\nThe list");
    for(var nextUpItem in list) {
      print("${nextUpItem.member.firstName} ${nextUpItem.member.lastName} -- ${nextUpItem.lastServedDate}");
    }
  }

  void add(NextUpItem item) {
    if(_pointers.containsKey(item.member.guid)) {
      var existingItem = _pointers[item.member.guid];
      list.remove(existingItem);
    }
    list.add(item);
    _pointers[item.member.guid] = item;
  }
}

class NextUpItem {
  Member member;
  DateTime? lastServedDate;
  ServiceInstance? lastServedService;

  NextUpItem(this.member, {this.lastServedDate, this.lastServedService});
}
