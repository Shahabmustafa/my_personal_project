import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/website/website_app.dart';

/// Runs the customer website (no Supabase needed):
/// flutter run -d chrome -t lib/main_website.dart
/// flutter build web -t lib/main_website.dart
void main() {
  runApp(const ProviderScope(child: WebsiteApp()));
}
