import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/current_branch_provider.dart';
import '../../data/datasource/branch_overview_datasource.dart';
import '../../data/model/branch_overview_model.dart';
import '../../data/repository/branch_overview_repository.dart';

final branchOverviewDatasourceProvider = Provider<BranchOverviewDatasource>(
  (ref) => BranchOverviewDatasource(Supabase.instance.client),
);

final branchOverviewRepositoryProvider = Provider<BranchOverviewRepository>(
  (ref) => BranchOverviewRepository(ref.read(branchOverviewDatasourceProvider)),
);

final branchOverviewProvider = FutureProvider<BranchOverviewData>(
  (ref) => ref
      .read(branchOverviewRepositoryProvider)
      .getOverview(ref.watch(currentBranchIdProvider)),
);
