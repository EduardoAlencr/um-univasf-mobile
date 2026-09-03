import 'package:flutter/material.dart';
import '../state/auth_scope.dart';
import '../widgets/tab_bar_shell.dart';
import '../widgets/um_app_bar.dart';
import '../navigation/go_profile.dart';
import 'calendario_lock_screen.dart';
import 'calendario_screen.dart';
import 'discente_screen.dart';
import 'home_screen.dart';
import 'notificacoes_screen.dart';
import 'perfil_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final loggedIn = AuthScope.of(context).loggedIn;

    Widget body;
    switch (_tab) {
      case 1:
        body = const NotificacoesScreen();
        break;
      case 3:
        body = loggedIn
            ? const CalendarioScreen()
            : CalendarioLockScreen(
                onLogin: () => goProfile(context),
                onContinue: () => setState(() => _tab = 0),
              );
        break;
      case 4:
        body = loggedIn ? const PerfilScreen() : const _RedirectToProfileOnce();
        break;
      default:
        body = HomeScreen(onOpenNotif: () => setState(() => _tab = 1));
    }

    return TabBarShell(
      currentIndex: _tab,
      onTabSelected: (i) => setState(() => _tab = i),
      onFabTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiscenteScreen())),
      body: Scaffold(
        appBar: UmAppBar(onAvatarTap: () => goProfile(context)),
        body: body,
      ),
    );
  }
}

/// Se o usuário não estiver logado e cair na aba Perfil, encaminha para o login
/// (equivalente ao goProfile() do protótipo HTML) e volta para Início.
class _RedirectToProfileOnce extends StatefulWidget {
  const _RedirectToProfileOnce();

  @override
  State<_RedirectToProfileOnce> createState() => _RedirectToProfileOnceState();
}

class _RedirectToProfileOnceState extends State<_RedirectToProfileOnce> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      goProfile(context);
      final shellState = context.findAncestorStateOfType<_RootShellState>();
      shellState?.setState(() => shellState._tab = 0);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
