import 'package:flutter/material.dart';

class ClinicalReasoningDashboard extends StatefulWidget {
  const ClinicalReasoningDashboard({super.key});

  @override
  State<ClinicalReasoningDashboard> createState() =>
      _ClinicalReasoningDashboardState();
}

class _ClinicalReasoningDashboardState
    extends State<ClinicalReasoningDashboard> {
  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _bg = Color(0xFFF5F7FB);

  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'all'; // 'all' | 'active' | 'beta' | 'stable'

  // ── Agent registry ─────────────────────────────────────────────────────────
  // TODO: Replace with real fetch from orchestrator server when ready
  static const List<Map<String, String>> _allAgents = [
    {
      'name': 'Patient Diagnostic Router',
      'desc': 'Routes symptom queries to appropriate diagnostic APIs',
      'endpoint': '/orchestrator/api/orchestrate',
      'status': 'active',
      'category': 'Diagnostic',
    },
    {
      'name': 'Appointment Scheduler',
      'desc': 'Finds and books appointments by querying doctor availability',
      'endpoint': '/orchestrator/schedule',
      'status': 'stable',
      'category': 'Scheduling',
    },
    {
      'name': 'Medication Interaction Checker',
      'desc': 'Cross-references prescriptions against new medications',
      'endpoint': '/orchestrator/med-check',
      'status': 'active',
      'category': 'Medication',
    },
    {
      'name': 'Lab Results Interpreter',
      'desc': 'Generates plain-language summaries of blood and imaging results',
      'endpoint': '/orchestrator/lab-interpret',
      'status': 'beta',
      'category': 'Diagnostic',
    },
    {
      'name': 'Referral Coordinator',
      'desc': 'Orchestrates specialist referral workflows end to end',
      'endpoint': '/orchestrator/referral',
      'status': 'active',
      'category': 'Workflow',
    },
    {
      'name': 'Clinical Staff Dispatcher',
      'desc': 'Allocates clinical staff based on workload and patient priority',
      'endpoint': '/orchestrator/dispatch',
      'status': 'beta',
      'category': 'Workflow',
    },
    {
      'name': 'Billing & Insurance Router',
      'desc': 'Resolves billing queries across insurance and fee schedule APIs',
      'endpoint': '/orchestrator/billing',
      'status': 'stable',
      'category': 'Billing',
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filtered {
    final q = _searchController.text.toLowerCase();
    return _allAgents.where((a) {
      final matchQ = q.isEmpty ||
          a['name']!.toLowerCase().contains(q) ||
          a['endpoint']!.toLowerCase().contains(q) ||
          a['desc']!.toLowerCase().contains(q) ||
          a['category']!.toLowerCase().contains(q);
      final matchF = _activeFilter == 'all' || a['status'] == _activeFilter;
      return matchQ && matchF;
    }).toList();
  }

  int get _activeCount =>
      _allAgents.where((a) => a['status'] == 'active').length;
  int get _betaCount => _allAgents.where((a) => a['status'] == 'beta').length;

  // ── Status helpers ─────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return const Color(0xFF10B981);
      case 'beta':   return const Color(0xFFF59E0B);
      case 'stable': return const Color(0xFF3B82F6);
      default:       return Colors.grey;
    }
  }

  Color _categoryBg(String category) {
    switch (category) {
      case 'Diagnostic':  return const Color(0xFFEEF2FF);
      case 'Scheduling':  return const Color(0xFFECFDF5);
      case 'Medication':  return const Color(0xFFFFFBEB);
      case 'Workflow':    return const Color(0xFFF5F3FF);
      case 'Billing':     return const Color(0xFFF0F9FF);
      default:            return const Color(0xFFF3F4F6);
    }
  }

  Color _categoryFg(String category) {
    switch (category) {
      case 'Diagnostic':  return const Color(0xFF1E4ED8);
      case 'Scheduling':  return const Color(0xFF065F46);
      case 'Medication':  return const Color(0xFF92400E);
      case 'Workflow':    return const Color(0xFF5B21B6);
      case 'Billing':     return const Color(0xFF0369A1);
      default:            return const Color(0xFF374151);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Diagnostic':  return Icons.biotech_outlined;
      case 'Scheduling':  return Icons.calendar_today_outlined;
      case 'Medication':  return Icons.medication_outlined;
      case 'Workflow':    return Icons.account_tree_outlined;
      case 'Billing':     return Icons.receipt_long_outlined;
      default:            return Icons.hub_outlined;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patient Portal / CRD',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 4),
                const Text('Clinical Reasoning Dashboard',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(
                  'Search and interact with connected API agents for clinical decision support.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row: search + stats ────────────────────────────
                  LayoutBuilder(builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 600;
                    if (narrow) {
                      return Column(children: [
                        _buildSearchSection(),
                        const SizedBox(height: 12),
                        _buildStatsRow(),
                      ]);
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildSearchSection()),
                        const SizedBox(width: 16),
                        _buildStatsColumn(),
                      ],
                    );
                  }),

                  const SizedBox(height: 16),

                  // ── Agent list window ──────────────────────────────────
                  _buildAgentWindow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search section ─────────────────────────────────────────────────────────

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Search agents',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, endpoint, or capability...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: _primary, width: 1)),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text('Filter:',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[400])),
                const SizedBox(width: 8),
                ..._buildFilterChips(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFilterChips() {
    final filters = [
      ('All', 'all'),
      ('Active', 'active'),
      ('Beta', 'beta'),
      ('Stable', 'stable'),
    ];
    return filters.map((f) {
      final selected = _activeFilter == f.$2;
      return GestureDetector(
        onTap: () => setState(() => _activeFilter = f.$2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? _primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? _primary : const Color(0xFFE5E7EB),
                width: 0.5),
          ),
          child: Text(f.$1,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey[600])),
        ),
      );
    }).toList();
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  Widget _buildStatsColumn() {
    return SizedBox(
      width: 160,
      child: Column(children: [
        _statCard('Active agents', _activeCount, '● All systems online',
            const Color(0xFF10B981)),
        const SizedBox(height: 10),
        _statCard('Beta agents', _betaCount, '● In testing',
            const Color(0xFFF59E0B)),
      ]),
    );
  }

  Widget _buildStatsRow() {
    return Row(children: [
      Expanded(
          child: _statCard('Active agents', _activeCount,
              '● All systems online', const Color(0xFF10B981))),
      const SizedBox(width: 10),
      Expanded(
          child: _statCard('Beta agents', _betaCount, '● In testing',
              const Color(0xFFF59E0B))),
    ]);
  }

  Widget _statCard(
      String label, int value, String sub, Color subColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Column(children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('$value',
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827))),
        const SizedBox(height: 4),
        Text(sub, style: TextStyle(fontSize: 11, color: subColor)),
      ]),
    );
  }

  // ── Agent window ───────────────────────────────────────────────────────────

  Widget _buildAgentWindow() {
    final list = _filtered;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(children: [
              const Text('Connected agents',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                    '${list.length} agent${list.length == 1 ? '' : 's'}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[500])),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // List — fixed height scrollable window
          SizedBox(
            height: 380,
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No agents match your search',
                            style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, color: Color(0xFFF3F4F6)),
                    itemBuilder: (ctx, i) => _agentRow(list[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _agentRow(Map<String, String> agent) {
    final category = agent['category']!;
    final status = agent['status']!;

    return InkWell(
      onTap: () {
        // TODO: Open agent-specific UI inside the window
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${agent['name']} — agent UI coming soon'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(children: [
          // Category icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _categoryBg(category),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_categoryIcon(category),
                color: _categoryFg(category), size: 18),
          ),
          const SizedBox(width: 14),

          // Name + description
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(agent['name']!,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827))),
                  const SizedBox(height: 2),
                  Text(agent['desc']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[400])),
                  const SizedBox(height: 4),
                  Text(agent['endpoint']!,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                          fontFamily: 'monospace')),
                ]),
          ),
          const SizedBox(width: 12),

          // Status dot
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _statusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),

          // Arrow
          Icon(Icons.chevron_right,
              color: Colors.grey[300], size: 20),
        ]),
      ),
    );
  }
}