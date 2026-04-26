import 'package:flutter/material.dart';
import '../view/specific_trial_info_page.dart';
import 'trial_patients_table.dart';
import 'matched_patients_table.dart';

class PharmaceuticalsSpecificTrialPage extends StatelessWidget {
  const PharmaceuticalsSpecificTrialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pages / Clinical Trial / Specific Trial',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9AA3B2),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 18,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const Text(
                      'Click back to the list',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit button clicked'),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const SpecificTrialInfoPage(
                  embedded: true,
                ),
                const SizedBox(height: 24),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: MatchedPatientsTable(),
                    ),
                    SizedBox(width: 18),
                    Expanded(
                      child: TrialPatientsTable(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
