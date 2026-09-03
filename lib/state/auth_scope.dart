import 'package:flutter/widgets.dart';
import 'auth_state.dart';

class AuthScope extends InheritedNotifier<AuthState> {
  const AuthScope({super.key, required AuthState super.notifier, required super.child});

  static AuthState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in context');
    return scope!.notifier!;
  }
}
