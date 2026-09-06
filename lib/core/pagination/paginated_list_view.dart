import 'package:flutter/material.dart';

import 'paginated_list_state.dart';

/// Infinite-scrolling body for a server-paginated list.
///
/// Handles: first-load spinner, first-load error + retry, empty state,
/// pull-to-refresh, scroll-near-bottom `loadMore`, and a footer that shows a
/// small spinner while the next page loads or a retry chip if it failed.
///
/// The caller keeps full control of each row via [itemBuilder]; pass
/// [gridDelegate] for a `GridView` layout, otherwise it is a `ListView`
/// (optionally with [separatorBuilder]). A fixed table header can sit above
/// this widget untouched.
class PaginatedListView<T> extends StatefulWidget {
  final PaginatedListState<T> state;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;
  final VoidCallback? onRetry;

  final IndexedWidgetBuilder? separatorBuilder;
  final SliverGridDelegate? gridDelegate;
  final EdgeInsetsGeometry padding;
  final Widget? emptyState;
  final String emptyText;

  const PaginatedListView({
    super.key,
    required this.state,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.onRefresh,
    this.onRetry,
    this.separatorBuilder,
    this.gridDelegate,
    this.padding = const EdgeInsets.all(16),
    this.emptyState,
    this.emptyText = 'No records found',
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;

    if (s.showInitialLoader) {
      return const Center(child: CircularProgressIndicator());
    }
    if (s.showFirstError) {
      return _ErrorView(
        message: s.error!,
        onRetry: widget.onRetry ?? () => widget.onRefresh(),
      );
    }
    if (s.showEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          controller: _controller,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: widget.emptyState ?? _EmptyView(text: widget.emptyText),
            ),
          ],
        ),
      );
    }

    final rows = s.rows;
    final footer = _Footer(state: s, onRetry: widget.onLoadMore);

    Widget list;
    if (widget.gridDelegate != null) {
      list = CustomScrollView(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: widget.padding,
            sliver: SliverGrid(
              gridDelegate: widget.gridDelegate!,
              delegate: SliverChildBuilderDelegate(
                (context, i) => widget.itemBuilder(context, rows[i], i),
                childCount: rows.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: footer),
        ],
      );
    } else if (widget.separatorBuilder != null) {
      list = ListView.separated(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: widget.padding,
        itemCount: rows.length + 1,
        separatorBuilder: (c, i) =>
            i >= rows.length - 1 ? const SizedBox.shrink() : widget.separatorBuilder!(c, i),
        itemBuilder: (context, i) => i == rows.length
            ? footer
            : widget.itemBuilder(context, rows[i], i),
      );
    } else {
      list = ListView.builder(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: widget.padding,
        itemCount: rows.length + 1,
        itemBuilder: (context, i) => i == rows.length
            ? footer
            : widget.itemBuilder(context, rows[i], i),
      );
    }

    return RefreshIndicator(onRefresh: widget.onRefresh, child: list);
  }
}

class _Footer<T> extends StatelessWidget {
  final PaginatedListState<T> state;
  final Future<void> Function() onRetry;

  const _Footer({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry loading more'),
          ),
        ),
      );
    }
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!state.hasMore && state.rows.length > state.pageSize) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text('End of list',
              style: TextStyle(fontSize: 12, color: Color(0xFFB0B5C8))),
        ),
      );
    }
    return const SizedBox(height: 12);
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44, color: Colors.redAccent),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF8A8FA3))),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

class _EmptyView extends StatelessWidget {
  final String text;
  const _EmptyView({required this.text});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(text, style: const TextStyle(color: Color(0xFF8A8FA3))),
          ],
        ),
      );
}
