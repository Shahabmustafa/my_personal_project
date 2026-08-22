import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/bank_datasource.dart';
import '../../data/repositories/bank_repository.dart';
import '../../data/models/bank_head_model.dart';
import '../../data/models/bank_entry_model.dart';

final bankDatasourceProvider = Provider<BankDatasource>(
  (_) => BankDatasource(Supabase.instance.client),
);

final bankRepositoryProvider = Provider<BankRepository>(
  (ref) => BankRepository(ref.watch(bankDatasourceProvider)),
);

final bankHeadsProvider = FutureProvider<List<BankHeadModel>>(
  (ref) => ref.watch(bankRepositoryProvider).getBankHeads(),
);

final bankEntriesProvider = FutureProvider<List<BankEntryModel>>(
  (ref) => ref.watch(bankRepositoryProvider).getBankEntries(),
);
