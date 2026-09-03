import 'package:flutter/material.dart';
import '../state/auth_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/um_app_bar.dart';
import '../screens/login_screen.dart';
import '../screens/perfil_screen.dart';

void goProfile(BuildContext context) {
  final loggedIn = AuthScope.of(context).loggedIn;
  if (!loggedIn) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (ctx) => Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: BackRow(label: 'Voltar', onTap: () => Navigator.of(ctx).pop()),
                ),
              ),
              const Expanded(child: PerfilScreen()),
            ],
          ),
        ),
      ),
    ),
  );
}
