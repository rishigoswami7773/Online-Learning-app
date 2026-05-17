import 'package:flutter/material.dart';

import 'sidebar.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final List<Widget> sideItems;
  final String title;
  const ResponsiveScaffold({super.key, required this.body, required this.sideItems, this.title = ''});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final isWide = constraints.maxWidth > 900;
      if (isWide) {
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Row(
            children: [
              SizedBox(width: 240, child: Sidebar(items: sideItems)),
              Expanded(child: body),
            ],
          ),
        );
      }
      return Scaffold(appBar: AppBar(title: Text(title)), drawer: Sidebar(items: sideItems), body: body);
    });
  }
}
