import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../superadmin/shared/current_head_office_provider.dart';
import '../../../shared/current_branch_provider.dart';
import '../../data/datasource/sale_claim_datasource.dart';
import '../../data/model/sale_claim_model.dart';
import '../../data/repository/sale_claim_repository.dart';

final saleClaimRepositoryProvider = Provider<SaleClaimRepository>(
  (_) => SaleClaimRepository(SaleClaimDatasource(Supabase.instance.client)),
);

/// Is branch ke apne claims.
final branchSaleClaimsProvider = FutureProvider<List<SaleClaimModel>>((ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId.isEmpty) return const [];
  return ref.watch(saleClaimRepositoryProvider).getBranchClaims(branchId);
});

/// Head Office ko sab branches se aaye claims.
final incomingSaleClaimsProvider = FutureProvider<List<SaleClaimModel>>((
  ref,
) async {
  final headOfficeId = await ref.watch(headOfficeIdProvider.future);
  if (headOfficeId.isEmpty) return const [];
  return ref.watch(saleClaimRepositoryProvider).getIncomingClaims(headOfficeId);
});
