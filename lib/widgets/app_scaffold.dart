import 'package:flutter/material.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/widgets/sidebar_widget.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final String selectedItem;
  final void Function(String) onItemSelected;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;
  final bool showCurrency;
  final Widget? floatingActionButton;

  const AppScaffold({
    Key? key,
    required this.title,
    required this.body,
    required this.selectedItem,
    required this.onItemSelected,
    this.bottom,
    this.actions,
    this.showCurrency = true,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: title,
        bottom: bottom,
        actions: actions,
        showCurrency: showCurrency,
      ),
      drawer: SidebarWidget(
        selectedItem: selectedItem,
        onItemSelected: onItemSelected,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
