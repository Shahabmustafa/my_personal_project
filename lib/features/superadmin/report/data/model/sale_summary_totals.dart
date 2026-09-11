/// Sale Summary screen ke top cards ke liye combined totals — teeno reports
/// (invoice, return, exchange) ka ek hi jagah snapshot.
class SaleSummaryTotals {
  final double totalSale;
  final double totalReturn;

  /// Exchange transactions mein customer se net collect (>0) ya net refund
  /// (<0) hua amount — [SaleExchangeModel.differenceAmount] ka sum.
  final double exchangeChange;
  final int invoiceCount;
  final int returnCount;
  final int exchangeCount;

  const SaleSummaryTotals({
    this.totalSale = 0,
    this.totalReturn = 0,
    this.exchangeChange = 0,
    this.invoiceCount = 0,
    this.returnCount = 0,
    this.exchangeCount = 0,
  });

  /// Net sale = total sale − total return ± exchange ka net effect.
  double get netTotalSale => totalSale - totalReturn + exchangeChange;
}
