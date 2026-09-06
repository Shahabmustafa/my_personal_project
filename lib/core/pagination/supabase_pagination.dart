import 'package:supabase_flutter/supabase_flutter.dart';

import 'page_models.dart';

/// Runs a composed Supabase query as one page.
///
/// The caller passes a query that already has its `.select(...)`, filters
/// (`.eq`, `.or`, `.ilike`, `.gte`, …) and `.order(...)` applied. This helper
/// adds `.range(from, to)` and — only when [PageRequest.withCount] is true —
/// `.count(CountOption.exact)`, so a page + its exact total come back in a
/// single round-trip. `count` respects filters but ignores `range`, so it is
/// the true filtered total, not just the page size.
///
/// Example:
/// ```dart
/// final base = _client.from('products').select('*');
/// final q = (req.search.isEmpty ? base : base.ilike('article_name', '%${req.search}%'))
///     .order('created_at', ascending: false);
/// final page = await runSupabasePage(q, request: req);
/// ```
Future<PageResult<Map<String, dynamic>>> runSupabasePage(
  PostgrestTransformBuilder<PostgrestList> query, {
  required PageRequest request,
}) async {
  if (request.withCount) {
    final res =
        await query.range(request.from, request.to).count(CountOption.exact);
    return PageResult(
      rows: res.data.cast<Map<String, dynamic>>(),
      totalCount: res.count,
    );
  }
  final rows = await query.range(request.from, request.to);
  return PageResult(
    rows: (rows as List).cast<Map<String, dynamic>>(),
    totalCount: -1,
  );
}
