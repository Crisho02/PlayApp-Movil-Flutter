import 'package:flutter/material.dart';
import 'screens/main_shell.dart';
import 'state/playapp_state.dart';
import 'theme/playapp_theme.dart';

void main() {
  runApp(const PlayAppMobile());
}

/// Aplicación móvil Flutter de PlayApp.
class PlayAppMobile extends StatefulWidget {
  const PlayAppMobile({super.key, this.initialState});

  final PlayAppState? initialState;

  @override
  State<PlayAppMobile> createState() => _PlayAppMobileState();
}

class _PlayAppMobileState extends State<PlayAppMobile> {
  late final PlayAppState _state = widget.initialState ?? PlayAppState();

  @override
  Widget build(BuildContext context) {
    return PlayAppScope(
      state: _state,
      child: MaterialApp(
        title: 'PlayApp Móvil',
        debugShowCheckedModeBanner: false,
        theme: buildPlayAppTheme(),
        home: const MainShell(),
      ),
    );
  }
}
