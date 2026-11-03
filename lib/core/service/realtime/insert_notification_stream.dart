import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [table] mein [column] == [value] wali nayi row insert hote hi us row ka
/// [numberField] emit karta hai — dashboards isay notification ki tarah
/// dikhate hain. [value] khali ho to kuch emit nahi hota.
Stream<String> insertNotificationStream(
  Ref ref, {
  required String channelName,
  required String table,
  required String column,
  required String value,
  required String numberField,
}) {
  final controller = StreamController<String>();
  if (value.isEmpty) return controller.stream;

  final client = Supabase.instance.client;
  final channel = client
      .channel(channelName)
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: column,
          value: value,
        ),
        callback: (payload) {
          final number = payload.newRecord[numberField]?.toString() ?? '';
          if (!controller.isClosed) controller.add(number);
        },
      )
      .subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
    controller.close();
  });
  return controller.stream;
}
