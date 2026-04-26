import 'package:flutter/material.dart';

class DashboardActionItem {
  final String name;
  final int completed;
  final int pending;

  const DashboardActionItem({
    required this.name,
    required this.completed,
    required this.pending,
  });

  int get total => completed + pending;
}

class DashboardActionsCarousel extends StatefulWidget {
  final List<DashboardActionItem> items;
  final Duration autoPlayDuration;
  final ValueChanged<DashboardActionItem>? onCardTap;

  const DashboardActionsCarousel({
    super.key,
    required this.items,
    this.autoPlayDuration = const Duration(milliseconds: 1500),
    this.onCardTap,
  });

  @override
  State<DashboardActionsCarousel> createState() =>
      _DashboardActionsCarouselState();
}

class _DashboardActionsCarouselState extends State<DashboardActionsCarousel> {
  int currentIndex = 0;

  void next() {
    if (widget.items.isEmpty) return;
    setState(() {
      currentIndex = (currentIndex + 1) % widget.items.length;
    });
  }

  void previous() {
    if (widget.items.isEmpty) return;
    setState(() {
      currentIndex =
          (currentIndex - 1 + widget.items.length) % widget.items.length;
    });
  }

  void jumpTo(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final item = widget.items[currentIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
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
            top: -40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CarouselDots(
                  currentIndex: currentIndex,
                  total: widget.items.length,
                  onDotClick: jumpTo,
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: previous,
                      color: const Color(0xFF1E4ED8),
                      icon: const Icon(Icons.keyboard_arrow_left),
                    ),
                    IconButton(
                      onPressed: next,
                      color: const Color(0xFF1E4ED8),
                      icon: const Icon(Icons.keyboard_arrow_right),
                    ),
                  ],
                )
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(19),
            onTap: () => widget.onCardTap?.call(item),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.name} Actions',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1E4ED8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have a total of ${item.total} ${item.name} actions',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.pending} pending, ${item.completed} completed',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1E4ED8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselDots extends StatelessWidget {
  final int currentIndex;
  final int total;
  final ValueChanged<int> onDotClick;

  const _CarouselDots({
    required this.currentIndex,
    required this.total,
    required this.onDotClick,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        total,
        (index) => GestureDetector(
          onTap: () => onDotClick(index),
          child: Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            child: Container(
              width: currentIndex == index ? 12 : 8,
              height: currentIndex == index ? 12 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentIndex == index
                    ? const Color(0xFF1E4ED8)
                    : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
