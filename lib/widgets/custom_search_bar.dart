import 'package:flutter/material.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class CustomSearchBar extends StatelessWidget {
  final String placeholder;
  final VoidCallback onTap;
  final VoidCallback onSearch;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final bool autofocus;

  const CustomSearchBar({
    Key? key,
    required this.placeholder,
    required this.onTap,
    required this.onSearch,
    this.controller,
    this.onChanged,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: controller != null
                ? TextField(
                    controller: controller,
                    onChanged: onChanged,
                    autofocus: autofocus,
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintStyle: AppTheme.textTheme.bodyMedium,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.only(left: 16, bottom: 4),
                    ),
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                    onSubmitted: (_) => onSearch(),
                  )
                : GestureDetector(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        placeholder,
                        style: AppTheme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.search,
                color: Colors.white,
                size: 22,
              ),
              onPressed: onSearch,
            ),
          ),
        ],
      ),
    );
  }
}
