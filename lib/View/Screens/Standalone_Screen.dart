import 'package:flutter/material.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/ICU_Dashboard_Screen.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/EHospitalExplainerApp.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/AgenticAI/agentic_ai_screen.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/Login_Screen.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/Psych_Screening_Screen.dart';

class StandaloneScreen extends StatelessWidget {
  const StandaloneScreen({super.key});

  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _bg      = Color(0xFFF5F7FB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // Top bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
            child: Row(
              children: [
                Image.asset('assets/ehospital_logo.png', height: 40, fit: BoxFit.contain),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('eHospital',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primary)),
                      Text('Standalone Tools',
                          style: TextStyle(fontSize: 12, color: Colors.black45)),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back to Login'),
                  style: TextButton.styleFrom(foregroundColor: Colors.black45),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Content
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Standalone Tools',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    const SizedBox(height: 8),
                    Text(
                      'Access specialised dashboards that operate independently of the main portals.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 40),

                    // Tool cards
                    LayoutBuilder(builder: (context, constraints) {
                      final wide = constraints.maxWidth > 600;
                      final cards = <Widget>[

                        // ── ICU Monitor ──────────────────────────────────
                        _ToolCard(
                          icon: Icons.monitor_heart_outlined,
                          iconBg: const Color(0xFFFEF2F2),
                          iconColor: const Color(0xFFDC2626),
                          title: 'ICU Monitor',
                          description: 'Real-time ICU patient vitals, alerts, and bed management dashboard.',
                          statusLabel: 'Live',
                          statusColor: const Color(0xFF10B981),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const IcuDashboardScreen()),
                          ),
                        ),

                        // ── Explainer App ─────────────────────────────────
                        _ToolCard(
                          icon: Icons.description_outlined,
                          iconBg: const Color(0xFFDAE3FF),
                          iconColor: _primary,
                          title: 'Explainer App',
                          description: 'AI-Powered Medical Report Translation.',
                          statusLabel: 'Live',
                          statusColor: const Color(0xFF10B981),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EHospitalExplainerApp()),
                          ),
                        ),

                        // ── Agentic AI ────────────────────────────────────
                        _ToolCard(
                          icon: Icons.hub_outlined,
                          iconBg: const Color(0xFFEEF2FF),
                          iconColor: _primary,
                          title: 'Agentic AI',
                          description: 'Multi-source healthcare data processing and insights workspace.',
                          statusLabel: 'Beta',
                          statusColor: const Color(0xFFF59E0B),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AgenticAIScreen()),
                          ),
                        ),

                        _ToolCard(
                          icon: Icons.psychology_outlined,
                          iconBg: const Color(0xFFEFFCF6),
                          iconColor: const Color(0xFF059669),
                          title: 'Psych Screening',
                          description: 'Questionnaire, scoring, AI chat, and doctor PDF export for psych screening.',
                          statusLabel: 'Live',
                          statusColor: const Color(0xFF10B981),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PsychScreeningScreen(),
                            ),
                          ),
                        ),

                        // ADD MORE TOOL CARDS HERE as new standalones arrive

                      ];

                      if (wide) {
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: cards.map((c) => SizedBox(width: 280, child: c)).toList(),
                        );
                      }
                      return Column(
                        children: cards.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 16), child: c)).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable tool card widget ─────────────────────────────────────────────────

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.statusLabel,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            const SizedBox(height: 6),
            Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4)),
            const SizedBox(height: 16),
            Row(children: [
              const Spacer(),
              Text('Open →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[400])),
            ]),
          ],
        ),
      ),
    );
  }
}
