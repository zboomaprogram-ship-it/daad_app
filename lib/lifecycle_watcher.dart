import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LifeCycleWatcher extends StatefulWidget {
  final Widget child;

  const LifeCycleWatcher({required this.child, super.key});

  @override
  _LifeCycleWatcherState createState() => _LifeCycleWatcherState();
}

class _LifeCycleWatcherState extends State<LifeCycleWatcher>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground → update lastSeenAt
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'lastSeenAt': FieldValue.serverTimestamp(),
        });
      }
      print('Donnnnnnne');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
