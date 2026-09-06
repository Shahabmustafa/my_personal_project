/// Request/response value objects shared by every server-paginated list.
///
/// A [PageRequest] is built by [PaginatedListNotifier] from the current list
/// state and passed to a datasource's `fetchPage`. The datasource composes its
/// Supabase query (filters + search + order), runs it through
/// `runSupabasePage`, and returns a [PageResult].
library;

class PageRequest {
  /// 1-based page number.
  final int page;
  final int pageSize;

  /// Free-text search — already sanitised for use inside PostgREST `or(...)` /
  /// `ilike(...)` (no commas, parens, `%`, `*`). Empty = no search.
  final String search;

  /// Column filters, e.g. `{'status': 'pending', 'branch_id': '…'}`.
  final Map<String, Object?> filters;

  final String? sortColumn;
  final bool sortAscending;

  /// When false the datasource should skip the `COUNT(*)` and return
  /// `totalCount: -1` — the notifier keeps the previously known total. Only the
  /// first page / a refresh / a search-or-filter change asks for the count.
  final bool withCount;

  const PageRequest({
    required this.page,
    required this.pageSize,
    this.search = '',
    this.filters = const {},
    this.sortColumn,
    this.sortAscending = false,
    this.withCount = true,
  });

  int get from => (page - 1) * pageSize;
  int get to => from + pageSize - 1;

  T? filter<T>(String key) => filters[key] as T?;
}

class PageResult<T> {
  final List<T> rows;

  /// Total rows matching the current filters/search, or `-1` when the request
  /// asked for no count (see [PageRequest.withCount]).
  final int totalCount;

  const PageResult({required this.rows, required this.totalCount});

  PageResult<R> map<R>(R Function(T) f) =>
      PageResult(rows: rows.map(f).toList(), totalCount: totalCount);
}

/// Strips characters that would break a PostgREST `or(...)` / `ilike` filter
/// string, so raw user input can be interpolated safely.
String sanitizeSearch(String raw) => raw
    .trim()
    .replaceAll(RegExp(r'[,()%*"\\]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
