import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:safishoe_app/features/superadmin/discount/data/model/b1g1_offer_model.dart';
import 'package:safishoe_app/features/superadmin/discount/presentation/providers/b1g1_offer_provider.dart';

/// Stock variant ki pehchan-IDs — stock models (branch / head office) inhein
/// B1G1 offer se match karne ke liye dete hain.
typedef StockVariantIds = ({
  String productId,
  String sizeId,
  String colorId,
  String brandId,
  String categoryId,
  String typeId,
});

/// "B1G1" nishan — jab [variants] mein se koi bhi aaj chalne wale Buy 1 Get 1
/// Free offer mein ho. Offer na ho (ya load na ho) to kuch nahi dikhta.
class B1g1StockBadge extends ConsumerWidget {
  final Iterable<StockVariantIds> variants;
  const B1g1StockBadge({super.key, required this.variants});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(runningB1g1OffersProvider).value;
    if (offers == null || offers.isEmpty) return const SizedBox.shrink();
    final inOffer = variants.any(
      (v) => offers.any(
        (o) => o.matches(
          productId: v.productId,
          variantKey: b1g1VariantKey(
            productId: v.productId,
            sizeId: v.sizeId,
            colorId: v.colorId,
            brandId: v.brandId,
            categoryId: v.categoryId,
            typeId: v.typeId,
          ),
          brandId: v.brandId,
          categoryId: v.categoryId,
        ),
      ),
    );
    if (!inOffer) return const SizedBox.shrink();
    return Tooltip(
      message: 'Buy 1 Get 1 Free offer chal raha hai',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFB74D)),
        ),
        child: Text(
          'B1G1',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.orange.shade800,
          ),
        ),
      ),
    );
  }
}
