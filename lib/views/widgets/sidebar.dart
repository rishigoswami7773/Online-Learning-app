import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final List<Widget> items;
  const Sidebar({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: items,
        ),
      ),
    );
  }
}
