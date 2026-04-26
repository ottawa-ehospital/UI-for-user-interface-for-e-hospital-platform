import 'package:flutter/material.dart';

class PharmaceuticalsMessagesPage extends StatelessWidget {
  const PharmaceuticalsMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pages / messages',
            style: TextStyle(fontSize: 12, color: Color(0xFF9AA3B2), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            height: 670,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 24, child: _MessageCategoryPanel()),
                SizedBox(width: 12),
                Expanded(flex: 38, child: _MessageListPanel()),
                SizedBox(width: 12),
                Expanded(flex: 38, child: _MessageDetailPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCategoryPanel extends StatelessWidget {
  const _MessageCategoryPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Send New Message'),
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.science_outlined, size: 18, color: Color(0xFF6B7280)),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('Doctor', style: TextStyle(fontSize: 15, color: Color(0xFF1F2937))),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(color: Color(0xFF1E88E5), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageListPanel extends StatelessWidget {
  const _MessageListPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Messages', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
          const SizedBox(height: 20),
          const SizedBox(
            height: 36,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text('No messages in this category.', style: TextStyle(fontSize: 14, color: Color(0xFF4B5563))),
        ],
      ),
    );
  }
}

class _MessageDetailPanel extends StatelessWidget {
  const _MessageDetailPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Center(
        child: Text(
          'Select a conversation to view details',
          style: TextStyle(fontSize: 18, color: Color(0xFF6B7280), fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}
