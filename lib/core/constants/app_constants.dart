class AppConstants {
  AppConstants._();

  // Supabase credentials - replace with your project values
  static const String supabaseUrl = 'https://jjqhglmaxlcrusmmxwgi.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_cS8IX_ntAcRH7YJErWi9YQ_fw8LzqXr';

  // SharedPreferences keys
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyUserRole = 'user_role';
  static const String keyBranchIds = 'branch_ids';
  static const String keyWarehouseIds = 'warehouse_ids';
  static const String keyIsLoggedIn = 'is_logged_in';

  // Responsive breakpoints
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;
}
