import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/providers/auth_provider.dart';

/// System mein sirf ek hi head office hota hai (DB par singleton unique index).
/// Ye provider us akele head office ka id fetch karta hai. Agar abhi tak koi
/// head office add nahi hua to khali string milti hai.
final headOfficeIdProvider = FutureProvider<String>((ref) async {
  final client = Supabase.instance.client;
  final res = await client
      .from('head_offices')
      .select('id')
      .order('created_at')
      .limit(1)
      .maybeSingle();

  if (res != null && res['id'] != null) {
    return res['id'] as String;
  }

  // Fallback: user ke sath assigned head office (agar koi ho).
  final user = ref.watch(authProvider).user;
  if (user != null && user.headOfficeIds.isNotEmpty) {
    return user.headOfficeIds.first;
  }
  return '';
});

/// Sync helper — jahan FutureProvider await nahi kiya ja sakta wahan iska
/// abhi tak resolve hua value (warna khali string).
final currentHeadOfficeIdProvider = Provider<String>((ref) {
  return ref.watch(headOfficeIdProvider).value ?? '';
});
