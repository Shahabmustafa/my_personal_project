import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/core/storage/tab_scoped_supabase_storage.dart';
import 'package:safishoe_app/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/screens/login_screen.dart';

final supabase = Supabase.instance.client;

const _supabaseUrl = 'https://jjqhglmaxlcrusmmxwgi.supabase.co';

void main()async{
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: 'sb_publishable_cS8IX_ntAcRH7YJErWi9YQ_fw8LzqXr',
    // On web, keep each browser tab's login session in that tab only —
    // otherwise logging in as one role in another tab overwrites the shared
    // localStorage session used by every tab on the same origin.
    authOptions: FlutterAuthClientOptions(
      localStorage: TabScopedLocalStorage(
        persistSessionKey:
            'sb-${Uri.parse(_supabaseUrl).host.split(".").first}-auth-token',
      ),
      pkceAsyncStorage: TabScopedGotrueAsyncStorage(),
    ),
  );
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: LoginScreen(),
    );
  }
}

