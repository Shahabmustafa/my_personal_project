import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import 'page_models.dart';
import 'paginated_list_state.dart';

/// Base class for every server-paginated list in the app.
///
/// Subclasses implement only [fetchPage]; this class owns page tracking,
/// debounced search, filter/sort changes, infinite-scroll `loadMore`, refresh,
/// and stale-response guarding. It stays a plain `StateNotifier` so existing
/// `StateNotifierProvider` wiring and screen code (`ref.watch(xProvider)`) keep
/// working unchanged.
///
/// Count is fetched from PostgreSQL only for the first page, a refresh, or a
/// search/filter/sort change — never while scrolling.
abstract class PaginatedListNotifier<T>
    extends StateNotifier<PaginatedListState<T>> {
  PaginatedListNotifier({
    int pageSize = 50,
    Map<String, Object?> initialFilters = const {},
    String? initialSortColumn,
    bool initialSortAscending = false,
    bool autoLoad = true,
  }) : super(PaginatedListState<T>(
          pageSize: pageSize,
          filters: initialFilters,
          sortColumn: initialSortColumn,
          sortAscending: initialSortAscending,
        )) {
    if (autoLoad) loadFirst();
  }

  static const _debounceDuration = Duration(milliseconds: 350);

  Timer? _debounce;

  /// Bumped on every reset (first load, refresh, search/filter/sort change).
  /// A `loadMore` that finishes after a bump is discarded.
  int _generation = 0;

  /// Implemented by each list's datasource wrapper.
  Future<PageResult<T>> fetchPage(PageRequest request);

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> loadFirst() => _resetAndLoad();

  Future<void> refresh() => _resetAndLoad(isRefresh: true);

  void setSearch(String value) {
    final next = sanitizeSearch(value);
    if (next == state.search) return;
    state = state.copyWith(search: next);
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, _resetAndLoad);
  }

  /// Merge-updates the filter map. Pass `null` for a key to remove it.
  void setFilters(Map<String, Object?> patch) {
    final next = Map<String, Object?>.from(state.filters);
    for (final entry in patch.entries) {
      if (entry.value == null) {
        next.remove(entry.key);
      } else {
        next[entry.key] = entry.value;
      }
    }
    state = state.copyWith(filters: next);
    _resetAndLoad();
  }

  void clearFilters() {
    if (state.filters.isEmpty && state.search.isEmpty) return;
    state = state.copyWith(filters: const {}, search: '');
    _resetAndLoad();
  }

  void setSort(String? column, {bool ascending = false}) {
    if (column == state.sortColumn && ascending == state.sortAscending) return;
    state = state.copyWith(
      sortColumn: column,
      clearSortColumn: column == null,
      sortAscending: ascending,
    );
    _resetAndLoad();
  }

  Future<void> loadMore() async {
    if (state.isFirstLoad ||
        state.isLoadingMore ||
        state.isRefreshing ||
        !state.hasMore) {
      return;
    }
    final generation = _generation;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);
    try {
      final result =
          await fetchPage(state.requestFor(nextPage, withCount: false));
      if (generation != _generation) return;
      state = state.copyWith(
        rows: [...state.rows, ...result.rows],
        totalCount:
            result.totalCount < 0 ? state.totalCount : result.totalCount,
        page: nextPage,
        isLoadingMore: false,
      );
    } catch (e) {
      if (generation != _generation) return;
      state = state.copyWith(isLoadingMore: false, loadMoreError: _message(e));
    }
  }

  /// Optimistic helpers for the mutation methods subclasses already have
  /// (create/update/delete) — avoid a full round-trip where possible.
  void replaceRow(bool Function(T) match, T updated) {
    state = state.copyWith(
      rows: [for (final r in state.rows) match(r) ? updated : r],
    );
  }

  void removeRow(bool Function(T) match) {
    final kept = state.rows.where((r) => !match(r)).toList();
    if (kept.length == state.rows.length) return;
    state = state.copyWith(
      rows: kept,
      totalCount: state.totalCount > 0 ? state.totalCount - 1 : 0,
    );
  }

  Future<void> _resetAndLoad({bool isRefresh = false}) async {
    _debounce?.cancel();
    final generation = ++_generation;
    state = state.copyWith(
      isFirstLoad: !isRefresh,
      isRefreshing: isRefresh,
      clearError: true,
      clearLoadMoreError: true,
      page: 1,
    );
    try {
      final result = await fetchPage(state.requestFor(1, withCount: true));
      if (generation != _generation) return;
      state = state.copyWith(
        rows: result.rows,
        totalCount: result.totalCount < 0 ? 0 : result.totalCount,
        page: 1,
        isFirstLoad: false,
        isRefreshing: false,
      );
    } catch (e) {
      if (generation != _generation) return;
      state = state.copyWith(
        isFirstLoad: false,
        isRefreshing: false,
        error: _message(e),
      );
    }
  }

  String _message(Object e) => e.toString().replaceAll('Exception: ', '');
}
