/// Ek report page ka result — `rows` sirf current page ke (server-side
/// `.range()` se paginated), jabke `totalCount`/`totalQuantity`/`totalAmount`
/// UNFILTERED page ke bajaye poori (date-filtered) list par calculate hote
/// hain, taake summary cards hamesha "grand total" dikhayein, page switch
/// karne se na badlein.
class ReportPageResult<T> {
  final List<T> rows;
  final int totalCount;
  final int totalQuantity;
  final double totalAmount;

  const ReportPageResult({
    required this.rows,
    required this.totalCount,
    required this.totalQuantity,
    required this.totalAmount,
  });

  static ReportPageResult<E> empty<E>() => ReportPageResult<E>(
        rows: const [],
        totalCount: 0,
        totalQuantity: 0,
        totalAmount: 0,
      );
}
