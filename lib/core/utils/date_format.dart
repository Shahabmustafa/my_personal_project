/// App-wide date/time display: "03/11/2026 10:25 PM" (local time, 12-hour).
///
/// Sirf un fields par use karein jo asli timestamp hain (created_at,
/// assigned_at, paid_at...). DATE columns (invoice_date, counter_date) mein
/// time hota hi nahi — wahan date-only dikhana sahi hai.
library;

String fmtDateOnly(DateTime d) {
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/'
      '${l.month.toString().padLeft(2, '0')}/${l.year}';
}

String fmtDateTime(DateTime d) {
  final l = d.toLocal();
  final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
  final ampm = l.hour < 12 ? 'AM' : 'PM';
  return '${fmtDateOnly(l)} ${h.toString().padLeft(2, '0')}:'
      '${l.minute.toString().padLeft(2, '0')} $ampm';
}
