import 'package:flutter/material.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/ICU_Dashboard_Screen.dart';

class TasksSection extends StatefulWidget {
  const TasksSection({super.key});

  @override
  State<TasksSection> createState() => _TasksSectionState();
}

class _TasksSectionState extends State<TasksSection> {
  int tab = 0; // 0 Today, 1 Completed, 2 All

  final List<Map<String, dynamic>> tasks = [
    {
      "title": "Review Lab Results – Kate Y",
      "time": "June 21st, 9:00 AM",
      "done": false,
      "flagColor": const Color(0xFFEF4444),
    },
    {
      "title": "Sign off on encounter notes",
      "time": "June 21st, 11:00 AM",
      "done": false,
      "flagColor": const Color(0xFF22C55E),
    },
    {
      "title": "Update allergy info for David S.",
      "time": "June 21st, 2:00 PM",
      "done": false,
      "flagColor": const Color(0xFFF59E0B),
    },
  ];

  List<Map<String, dynamic>> get filtered {
    if (tab == 0) return tasks.where((t) => t["done"] == false).toList();
    if (tab == 1) return tasks.where((t) => t["done"] == true).toList();
    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    const panelBg = Color(0xFFF1F5FF); // light blue panel like screenshot
    const cardBg = Color(0xFFEFF6FF);  // stat card bg (very light)
    const primary = Color(0xFF1E4ED8);

    return Column(
      children: [
        // ===== Stats (2 columns, 3 rows) =====
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 62, // fixed height like screenshot
          ),
          children: const [
            _StatCard(title: "Total Patients", value: "78", bg: cardBg),
            _StatCard(title: "Appointments Today", value: "7", bg: cardBg),
            _StatCard(title: "Unfinished Notes", value: "2", bg: cardBg),
            _StatCard(title: "Unviewed Results", value: "6", bg: cardBg),
            _StatCard(title: "Unbilled Visits", value: "1", bg: cardBg),
            _StatCard(title: "Unsigned Notes", value: "3", bg: cardBg),
          ],
        ),

        const SizedBox(height: 14),

        // ===== ICU Monitor button =====
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IcuDashboardScreen()),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF003399), Color(0xFF1E4ED8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monitor_heart, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'ICU Monitor',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 13),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ===== Tasks panel (light-blue container) =====
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: panelBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                // Header row
                Row(
                  children: [
                    const Text(
                      "My Tasks",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primary, width: 1.4),
                      ),
                      child: const Icon(Icons.add, size: 18, color: primary),
                    )
                  ],
                ),

                const SizedBox(height: 12),

                // Tabs row
                Row(
                  children: [
                    _TabPill(
                      label: "Today",
                      selected: tab == 0,
                      onTap: () => setState(() => tab = 0),
                    ),
                    const SizedBox(width: 4),
                    _TabPill(
                      label: "Completed",
                      selected: tab == 1,
                      onTap: () => setState(() => tab = 1),
                    ),
                    const SizedBox(width: 4),
                    _TabPill(
                      label: "All",
                      selected: tab == 2,
                      onTap: () => setState(() => tab = 2),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),

                const SizedBox(height: 6),

                // Task list (no ListTile; custom rows like screenshot)
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final t = filtered[i];
                      return _TaskRow(
                        title: t["title"] as String,
                        time: t["time"] as String,
                        checked: t["done"] as bool,
                        flagColor: t["flagColor"] as Color,
                        onToggle: () {
                          setState(() => t["done"] = !(t["done"] as bool));
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color bg;

  const _StatCard({
    required this.title,
    required this.value,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1E4ED8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: primary, width: 1.4),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? Colors.white : primary,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String title;
  final String time;
  final bool checked;
  final Color flagColor;
  final VoidCallback onToggle;

  const _TaskRow({
    required this.title,
    required this.time,
    required this.checked,
    required this.flagColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Checkbox square
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 22,
              width: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black45, width: 1.6),
                color: checked ? const Color(0xFF1E4ED8) : Colors.transparent,
              ),
              child: checked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),

          const SizedBox(width: 12),

          // Title + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Flag + dots
          Icon(Icons.outlined_flag, color: flagColor, size: 20),
          const SizedBox(width: 10),
          const Icon(Icons.more_horiz, color: Colors.black54, size: 20),
        ],
      ),
    );
  }
}

