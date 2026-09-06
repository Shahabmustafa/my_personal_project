import 'page_models.dart';

/// Immutable state for a server-paginated list. One instance per list screen,
/// held by a [PaginatedListNotifier] subclass via a `StateNotifierProvider`
/// (same pattern as the rest of the app's notifiers).
class PaginatedListState<T> {
  final List<T> rows;

  /// Exact total matching the current search/filters (from PostgreSQL COUNT).
  final int totalCount;

  /// 1-based number of the last page currently loaded.
  final int page;
  final int pageSize;

  /// True until the very first page resolves (drives the full-screen spinner).
  final bool isFirstLoad;

  /// True while a `loadMore()` (next page) request is in flight.
  final bool isLoadingMore;

  /// True while a pull-to-refresh / mutation-triggered refresh is in flight.
  final bool isRefreshing;

  /// Fatal error for the first page (list could not load at all).
  final String? error;

  /// Non-fatal error for a `loadMore()` — existing rows stay visible.
  final String? loadMoreError;

  final String search;
  final Map<String, Object?> filters;
  final String? sortColumn;
  final bool sortAscending;

  const PaginatedListState({
    this.rows = const [],
    this.totalCount = 0,
    this.page = 1,
    this.pageSize = 50,
    this.isFirstLoad = true,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.error,
    this.loadMoreError,
    this.search = '',
    this.filters = const {},
    this.sortColumn,
    this.sortAscending = false,
  });

  bool get hasMore => totalCount < 0 ? true : rows.length < totalCount;
  bool get showInitialLoader => isFirstLoad && error == null;
  bool get showFirstError => error != null && rows.isEmpty;
  bool get showEmpty =>
      !isFirstLoad && !isRefreshing && error == null && rows.isEmpty;
  bool get hasActiveQuery => search.isNotEmpty || filters.isNotEmpty;

  PageRequest requestFor(int page, {required bool withCount}) => PageRequest(
        page: page,
        pageSize: pageSize,
        search: search,
        filters: filters,
        sortColumn: sortColumn,
        sortAscending: sortAscending,
        withCount: withCount,
      );

  PaginatedListState<T> copyWith({
    List<T>? rows,
    int? totalCount,
    int? page,
    int? pageSize,
    bool? isFirstLoad,
    bool? isLoadingMore,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    String? search,
    Map<String, Object?>? filters,
    String? sortColumn,
    bool clearSortColumn = false,
    bool? sortAscending,
  }) {
    return PaginatedListState<T>(
      rows: rows ?? this.rows,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      isFirstLoad: isFirstLoad ?? this.isFirstLoad,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
      search: search ?? this.search,
      filters: filters ?? this.filters,
      sortColumn: clearSortColumn ? null : (sortColumn ?? this.sortColumn),
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}
