import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safishoe_app/core/service/realtime/table_changes_provider.dart';
import '../../data/datasource/b1g1_offer_datasource.dart';
import '../../data/model/b1g1_offer_model.dart';

final b1g1OfferDatasourceProvider = Provider<B1g1OfferDatasource>(
  (_) => B1g1OfferDatasource(Supabase.instance.client),
);

/// Sab offers (admin screen) — purane pehle.
final b1g1OffersProvider = FutureProvider<List<B1g1OfferModel>>((ref) {
  ref.watch(tableChangesProvider('b1g1_offers'));
  return ref.read(b1g1OfferDatasourceProvider).getAll();
});

/// Sale Invoice ke liye — sirf aaj chalne wale offers. Load na ho sake
/// (ya table abhi na bana ho) to khali list, sale normal chalti rahe.
final runningB1g1OffersProvider =
    FutureProvider<List<B1g1OfferModel>>((ref) async {
  try {
    final all = await ref.watch(b1g1OffersProvider.future);
    final now = DateTime.now();
    return all.where((o) => o.isRunningOn(now)).toList();
  } catch (_) {
    return const [];
  }
});

final b1g1ProductsProvider = FutureProvider<List<B1g1Lookup>>(
    (ref) => ref.read(b1g1OfferDatasourceProvider).getProducts());

/// Article dropdown — har stock variant size/color/brand ke sath.
final b1g1VariantsProvider = FutureProvider<List<B1g1Variant>>(
    (ref) => ref.read(b1g1OfferDatasourceProvider).getVariants());
