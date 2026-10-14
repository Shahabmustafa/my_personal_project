import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/current_branch_provider.dart';

/// Branch ko naya stock assign hote hi (head office / warehouse / doosri
/// branch se) us assignment ka number emit karta hai — dashboard isay
/// notification ki tarah dikhata hai.
final incomingAssignmentProvider = StreamProvider<String>((ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  final controller = StreamController<String>();
  if (branchId.isEmpty) return controller.stream;

  final client = Supabase.instance.client;
  final channel = client
      .channel('incoming-assignment:$branchId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'assign_stock_to_branch',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'assigned_to',
          value: branchId,
        ),
        callback: (payload) {
          final number =
              payload.newRecord['assignment_number']?.toString() ?? '';
          if (!controller.isClosed) controller.add(number);
        },
      )
      .subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
    controller.close();
  });
  return controller.stream;
});
