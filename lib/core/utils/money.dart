/// Paisa-level rounding (2 decimals) — percent discount/commission se bante
/// fractional paisa ko save/display se pehle theek karta hai. Half-up; chhota
/// epsilon float ki wajah se 149.925 ke 149.92 ban jaane se bachata hai.
double roundMoney(double v) {
  final eps = v >= 0 ? 1e-9 : -1e-9;
  return ((v * 100) + eps).roundToDouble() / 100;
}
