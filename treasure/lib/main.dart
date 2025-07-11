import 'package:flutter/material.dart';

import '00.common/style/theme.dart';
import '01.home/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: globalTheme, home: HomePage());
  }
}
