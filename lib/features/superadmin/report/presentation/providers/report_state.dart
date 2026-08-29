/// Generic state shared by the three sale-report notifiers (invoice, return,
/// exchange) — page/date-range navigation logic is identical for all three,
/// only the fetch call and row type differ.
class ReportState<T> {
  final List<T> rows;
  final int totalCount;
  final int totalQuantity;
  final double totalAmount;
  final int page;
  final int pageSize;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isLoading;
  final String? error;

  const ReportState({
    this.rows = const [],
    this.totalCount = 0,
    this.totalQuantity = 0,
    this.totalAmount = 0,
    this.page = 1,
    this.pageSize = 20,
    this.startDate,
    this.endDate,
    this.isLoading = false,
    this.error,
  });

  int get totalPages => totalCount == 0 ? 1 : ((totalCount - 1) ~/ pageSize) + 1;
  bool get hasFilter => startDate != null || endDate != null;

  ReportState<T> copyWith({
    List<T>? rows,
    int? totalCount,
    int? totalQuantity,
    double? totalAmount,
    int? page,
    int? pageSize,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      ReportState<T>(
        rows: rows ?? this.rows,
        totalCount: totalCount ?? this.totalCount,
        totalQuantity: totalQuantity ?? this.totalQuantity,
        totalAmount: totalAmount ?? this.totalAmount,
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
        startDate: clearStartDate ? null : startDate ?? this.startDate,
        endDate: clearEndDate ? null : endDate ?? this.endDate,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}
