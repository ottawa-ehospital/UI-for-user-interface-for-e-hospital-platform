import 'package:flutter/material.dart';

class DashboardSummaryCard extends StatelessWidget {
  final String title;
  final double percent;
  final int total;
  final VoidCallback? onTap;

  const DashboardSummaryCard({
    super.key,
    required this.title,
    required this.percent,
    required this.total,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = percent > 0
        ? Icons.arrow_upward
        : percent < 0
            ? Icons.arrow_downward
            : Icons.keyboard_arrow_right;

    final iconColor = percent > 0
        ? Colors.green
        : percent < 0
            ? Colors.red
            : const Color(0xFF1E4ED8);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              onPressed: onTap,
              color: Colors.lightBlue,
              icon: const Icon(Icons.keyboard_double_arrow_right),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  total.toString(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconColor.withOpacity(0.16),
                      ),
                      child: Icon(
                        iconData,
                        size: 16,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${percent > 0 ? '+' : ''}${percent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'last 7 days',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}