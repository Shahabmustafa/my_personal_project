import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Add to pubspec.yaml:
///   shimmer: ^3.0.0
///   cached_network_image: ^3.4.1

/// A simple grey box used as a shimmer skeleton block.
/// Uses theme surface color so it looks right in light/dark mode.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

/// Wraps any skeleton layout with the shimmer shine effect.
/// Colors adapt automatically to light/dark theme.
class ShimmerWrapper extends StatelessWidget {
  final Widget child;

  const ShimmerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
      highlightColor: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5),
      child: child,
    );
  }
}

/// Skeleton for a single [ProductCard] — used in grids while products load.
class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: ShimmerBox(
              width: double.infinity,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: double.infinity, height: 12),
                SizedBox(height: 6),
                ShimmerBox(width: 80, height: 12),
                SizedBox(height: 8),
                ShimmerBox(width: 60, height: 14),
                SizedBox(height: 6),
                ShimmerBox(width: 50, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid of shimmering product cards — drop-in replacement for
/// `CircularProgressIndicator` wherever a product grid is loading.
class ProductGridShimmer extends StatelessWidget {
  final int itemCount;

  const ProductGridShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.62,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => const ProductCardShimmer(),
      ),
    );
  }
}

/// Sliver version, for use inside a CustomScrollView (e.g. HomeScreen).
class ProductGridShimmerSliver extends StatelessWidget {
  final int itemCount;

  const ProductGridShimmerSliver({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.62,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) =>
          const ShimmerWrapper(child: ProductCardShimmer()),
          childCount: itemCount,
        ),
      ),
    );
  }
}

/// Skeleton for the greeting row's avatar + name while the user loads.
class GreetingRowShimmer extends StatelessWidget {
  const GreetingRowShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Row(
        children: [
          const ShimmerBox(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ShimmerBox(width: 90, height: 10),
              SizedBox(height: 6),
              ShimmerBox(width: 130, height: 14),
            ],
          ),
          const Spacer(),
          const ShimmerBox(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for the product detail screen while a single product loads.
class ProductDetailShimmer extends StatelessWidget {
  const ProductDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(
              width: double.infinity,
              height: 340,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            const SizedBox(height: 20),
            const ShimmerBox(width: 120, height: 12),
            const SizedBox(height: 10),
            const ShimmerBox(width: 220, height: 18),
            const SizedBox(height: 14),
            const ShimmerBox(width: 160, height: 14),
            const SizedBox(height: 18),
            const ShimmerBox(width: 100, height: 24),
            const SizedBox(height: 24),
            const ShimmerBox(width: 60, height: 14),
            const SizedBox(height: 10),
            Row(
              children: List.generate(
                3,
                    (i) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ShimmerBox(
                    width: 60,
                    height: 40,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const ShimmerBox(width: 100, height: 14),
            const SizedBox(height: 8),
            const ShimmerBox(width: double.infinity, height: 12),
            const SizedBox(height: 6),
            const ShimmerBox(width: double.infinity, height: 12),
            const SizedBox(height: 6),
            const ShimmerBox(width: 200, height: 12),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for a single cart row, mirrors [CartItemTile]'s layout.
class CartItemShimmer extends StatelessWidget {
  const CartItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(
            width: 68,
            height: 68,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: double.infinity, height: 14),
                SizedBox(height: 6),
                ShimmerBox(width: 100, height: 10),
                SizedBox(height: 14),
                ShimmerBox(width: 80, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// List of shimmering cart rows for the cart screen's loading state.
class CartListShimmer extends StatelessWidget {
  final int itemCount;

  const CartListShimmer({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => const CartItemShimmer(),
      ),
    );
  }
}

/// Sliver version for use inside CustomScrollView (e.g. CartScreen).
class CartListShimmerSliver extends StatelessWidget {
  final int itemCount;

  const CartListShimmerSliver({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) => const CartItemShimmer(),
            childCount: itemCount,
          ),
        ),
      ),
    );
  }
}

/// Skeleton for the profile screen while the user's profile loads.
class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: ShimmerBox(
              width: 96,
              height: 96,
              borderRadius: BorderRadius.all(Radius.circular(48)),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: ShimmerBox(width: 140, height: 16)),
          const SizedBox(height: 8),
          const Center(child: ShimmerBox(width: 180, height: 12)),
          const SizedBox(height: 24),
          ShimmerBox(
            width: double.infinity,
            height: 170,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 20),
          ShimmerBox(
            width: double.infinity,
            height: 48,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 12),
          ShimmerBox(
            width: double.infinity,
            height: 48,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}