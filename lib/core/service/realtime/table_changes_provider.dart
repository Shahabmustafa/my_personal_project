import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Realtime — ek table par koi bhi insert/update/delete hote hi
/// naya value emit hota hai. List providers isay `ref.watch` karte hain
/// (ya StateNotifier ke liye `ref.listen`), taake doosre user ka kaam
/// (naya assignment, return, claim, payment, accept/reject) bina Refresh
/// dabaye screen par aa jaye.
///
/// Payload use nahi hota — sirf "kuch badla" ka signal hai; data wahi
/// filtered query dobara laati hai.
///
/// Table ka `supabase_realtime` publication mein hona zaroori hai
/// (core/service/realtime/realtime_migration.sql).
final tableChangesProvider = StreamProvider.family<int, String>((ref, table) {
  final client = Supabase.instance.client;
  final controller = StreamController<int>();
  var tick = 0;

  final channel = client
      .channel('table-changes:$table')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) {
          if (!controller.isClosed) controller.add(++tick);
        },
      )
      .subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
});
