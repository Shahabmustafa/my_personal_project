import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/pair_incentive/pair_incentive.dart';

final pairIncentiveDatasourceProvider = Provider<PairIncentiveDatasource>(
  (ref) => PairIncentiveDatasource(Supabase.instance.client),
);

/// (from, to, branchId) — mahina ya poora saal.
typedef PairIncentiveKey = (DateTime, DateTime, String);

final pairIncentiveProvider = FutureProvider.autoDispose
    .family<PairIncentiveData, PairIncentiveKey>((ref, key) {
      return ref
          .read(pairIncentiveDatasourceProvider)
          .fetch(key.$1, key.$2, branchId: key.$3);
    });

final pairIncentiveDaysProvider = FutureProvider.autoDispose
    .family<List<PairIncentiveDay>, (String, DateTime)>(
      (ref, key) =>
          ref.read(pairIncentiveDatasourceProvider).fetchDays(key.$1, key.$2),
    );

final pairIncentiveStartYearProvider = FutureProvider.autoDispose
    .family<int, String>(
      (ref, employeeId) =>
          ref.read(pairIncentiveDatasourceProvider).startYear(employeeId),
    );
