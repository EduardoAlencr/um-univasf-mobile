import 'package:flutter/material.dart';
import 'data/remote_data_loader.dart';
import 'screens/root_shell.dart';
import 'screens/welcome_screen.dart';
import 'state/auth_scope.dart';
import 'state/auth_state.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const UmUnivasfApp());
}

class UmUnivasfApp extends StatefulWidget {
  const UmUnivasfApp({super.key});

  @override
  State<UmUnivasfApp> createState() => _UmUnivasfAppState();
}

class _UmUnivasfAppState extends State<UmUnivasfApp> {
  final _authState = AuthState();
  bool _dataReady = false;
  bool _welcomeSeenThisSession = false;

  @override
  void initState() {
    super.initState();
    _authState.load();
    loadRemoteData().whenComplete(() {
      if (mounted) setState(() => _dataReady = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      notifier: _authState,
      child: MaterialApp(
        title: 'UM · UNIVASF Mobile',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: AnimatedBuilder(
          animation: _authState,
          builder: (context, _) {
            if (!_authState.ready || !_dataReady) {
              return const Scaffold(
                backgroundColor: AppColors.canvas,
                body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
              );
            }
            if (!_authState.welcomeDismissed && !_welcomeSeenThisSession) {
              return WelcomeScreen(onContinuar: () => setState(() => _welcomeSeenThisSession = true));
            }
            return const RootShell();
          },
        ),
      ),
    );
  }
}
