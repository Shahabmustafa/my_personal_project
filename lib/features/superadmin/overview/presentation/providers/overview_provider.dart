import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/overview_datasource.dart';

final overviewDatasourceProvider = Provider<OverviewDatasource>(
  (ref) => OverviewDatasource(Supabase.instance.client),
);

final overviewStatsProvider = FutureProvider.autoDispose<OverviewStats>(
  (ref) => ref.watch(overviewDatasourceProvider).fetchStats(),
);
