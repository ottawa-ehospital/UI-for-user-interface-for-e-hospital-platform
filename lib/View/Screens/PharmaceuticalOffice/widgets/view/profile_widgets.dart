import 'package:flutter/material.dart';

class ProfilePageTitle extends StatelessWidget {
  final String title;

  const ProfilePageTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E4ED8),
      ),
    );
  }
}

class ProfileSectionTitle extends StatelessWidget {
  final String title;

  const ProfileSectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E263B),
      ),
    );
  }
}

class TrialBasicInfoItem extends StatelessWidget {
  final String title;
  final String content;
  final double minHeight;

  const TrialBasicInfoItem({
    super.key,
    required this.title,
    required this.content,
    this.minHeight = 110,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E8F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E4ED8),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileTableCard extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final double height;

  const ProfileTableCard({
    super.key,
    required this.headers,
    required this.rows,
    this.height = 320,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1E4ED8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: headers
                  .map(
                    (header) => Expanded(
                      child: Text(
                        header,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                final isEven = index % 2 == 0;

                return Container(
                  color: isEven ? const Color(0xFFF9FAFB) : Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: row
                        .map(
                          (cell) => Expanded(
                            child: Text(
                              cell,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ManagementSideCard extends StatelessWidget {
  final String title;
  final List<SideCardItem> items;

  const ManagementSideCard({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E4ED8),
            ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
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

class SideCardItem {
  final String label;
  final String value;

  const SideCardItem({
    required this.label,
    required this.value,
  });
}

List<SideCardItem> buildSideCardItems(Map<String, String> data) {
  return data.entries
      .map((e) => SideCardItem(label: e.key, value: e.value))
      .toList();
}
