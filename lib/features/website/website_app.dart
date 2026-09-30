import 'package:flutter/material.dart';
import 'presentation/screen/website_shell.dart';
import 'presentation/theme/website_theme.dart';

/// Customer-facing Safi Shoes website — branches, map, shoe catalogue and ordering.
/// Uses static data from data/website_data.dart (no Supabase yet).
class WebsiteApp extends StatelessWidget {
  const WebsiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safi Shoes',
      debugShowCheckedModeBanner: false,
      theme: buildWebsiteTheme(),
      home: const WebsiteShell(),
    );
  }
}
