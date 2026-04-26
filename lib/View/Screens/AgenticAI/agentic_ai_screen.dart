import 'package:flutter/material.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/AgenticAI/workspace_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AgenticAIScreen
//
//  Entry point for the "Agentic AI for Multi-Source Healthcare Data Processing
//  and Insights" tool. Wraps WorkspacePage with the eHospital shell.
//
//  Used from:
//    - Standalone_Screen.dart → tool card
//
//  Backend URL is configurable — update _backendUrl when the team provides
//  the deployed endpoint.
// ─────────────────────────────────────────────────────────────────────────────

class AgenticAIScreen extends StatelessWidget {
  const AgenticAIScreen({super.key});

  // Update this when the backend is deployed
  static const String _backendUrl = 'http://localhost:8000';

  @override
  Widget build(BuildContext context) {
    return const WorkspacePage(baseUrl: _backendUrl);
  }
}