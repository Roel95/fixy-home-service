import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String viewMoreText;
  final VoidCallback onViewMore;

  const SectionHeader({
    super.key,
    required this.title,
    this.viewMoreText = 'Ver mas',
    required this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D3748),
              letterSpacing: -0.3,
            ),
          ),
          GestureDetector(
            onTap: onViewMore,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECF3),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D3748).withValues(alpha: 0.1),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                  const BoxShadow(
                    color: Color(0xFFFFFFFF),
                    offset: Offset(-3, -3),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Text(
                viewMoreText,
                style: const TextStyle(
                  color: Color(0xFF667EEA),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
