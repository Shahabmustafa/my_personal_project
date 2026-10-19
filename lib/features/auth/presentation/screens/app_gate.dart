import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/user_model.dart';
import '../providers/auth_provider.dart';
import 'auth_destination.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

enum _Phase { splash, login, app }

/// App ka pehla screen. Splash tab tak dikhta hai jab tak saved login check
/// na ho jaye (aur kam az kam [minSplash], taake animation poori dikhe).
/// Phir logged-in user seedha dashboard par jata hai — login screen kabhi
/// nahi dikhti; warna login screen.
///
/// Faisla ek hi dafa hota hai: login ke baad navigation LoginScreen khud
/// karti hai, aur logout par dashboards LoginScreen par bhejte hain.
class AppGate extends ConsumerStatefulWidget {
  final Duration minSplash;
  final Widget Function(UserModel user)? destinationBuilder;

  const AppGate({
    super.key,
    this.minSplash = const Duration(milliseconds: 1800),
    this.destinationBuilder,
  });

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  _Phase _phase = _Phase.splash;
  bool _minDone = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.minSplash, () {
      if (mounted) setState(() => _minDone = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (_phase == _Phase.splash && _minDone && auth.initialized) {
      _phase = auth.isAuthenticated ? _Phase.app : _Phase.login;
    }

    final Widget child;
    switch (_phase) {
      case _Phase.splash:
        child = const SplashScreen(key: ValueKey('splash'));
      case _Phase.app:
        final user = auth.user;
        child = user == null
            ? const LoginScreen(key: ValueKey('login'))
            : KeyedSubtree(
                key: const ValueKey('app'),
                child: (widget.destinationBuilder ?? destinationForUser)(user),
              );
      case _Phase.login:
        child = const LoginScreen(key: ValueKey('login'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: child,
    );
  }
}
