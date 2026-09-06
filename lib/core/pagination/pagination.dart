/// Reusable server-side pagination toolkit.
///
/// - [PageRequest] / [PageResult] — datasource contract
/// - [runSupabasePage] — one round-trip page + exact COUNT
/// - [PaginatedListState] / [PaginatedListNotifier] — Riverpod StateNotifier
///   with debounced search, filters, sort, infinite `loadMore`, refresh
/// - [PaginatedListView] — infinite-scroll body with pull-to-refresh
/// - [TotalCountLabel] — "Total X: 30,245"
library;

export 'page_models.dart';
export 'paginated_list_notifier.dart';
export 'paginated_list_state.dart';
export 'paginated_list_view.dart';
export 'supabase_pagination.dart';
export 'total_count_label.dart';
