import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_router.dart';

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
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
              context.push('/schedule');
            }, child: Text("Schedule Service")),
            ElevatedButton(onPressed: () {
              context.push(
                '/people/search',
                //extra: UserDetail(id: '123', name: 'Alex', age: 28),
              );
            }, child: Text("People Search")),
            ElevatedButton(onPressed: () {
              context.push('/profile');
            }, child: Text("My Profile")),
            ElevatedButton(onPressed: () {
              context.push(
                '/settings',
              );
            }, child: Text("Settings")),
            ElevatedButton(onPressed: () {
              ref.read(authProvider.notifier).logout();
            }, child: Text("Logout")),
          ],
        ),
      ),
    );
  }
}
