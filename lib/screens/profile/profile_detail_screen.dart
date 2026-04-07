import 'package:flutter/material.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class ProfileDetailScreen extends StatelessWidget {
  final String title;
  final Widget content;

  const ProfileDetailScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          title,
          style: AppTheme.textTheme.titleLarge,
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: content,
    );
  }
}
