import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:ehosptal_flutter_revamp/Service/API_service.dart';
import 'package:ehosptal_flutter_revamp/Service/session_storage.dart';

import 'package:ehosptal_flutter_revamp/Service/stt_service.dart';
import 'package:ehosptal_flutter_revamp/View/Widgets/voice_input_button.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class OrchestratorScreen extends StatefulWidget {
  final String doctorId;

  const OrchestratorScreen({
    super.key,
    required this.doctorId,
  });

  @override
  State<OrchestratorScreen> createState() => _OrchestratorScreenState();
}

class _OrchestratorScreenState extends State<OrchestratorScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final SttService _sttService;
  static const String _sessionKeyPrefix = "orchestrator_chat_";

  bool _isSending = false;

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          "Hello Doctor. I am your Clinical Analysis assistant. I can help with clinical reasoning, patient-flow suggestions, and decision support guidance.",
      isUser: false,
      time: DateTime.now(),
    ),
  ];

  bool get _isWide => MediaQuery.of(context).size.width >= 900;
  bool get _isCompact => MediaQuery.of(context).size.width < 700;
  double get _pagePadding => _isCompact ? 12 : 24;

  @override
  void initState() {
    super.initState();
  _sttService = SttService(apiKey: dotenv.env['OPENAI_API_KEY'] ?? '');
  _loadSessionHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

Future<void> _sendMessage([String? overrideText]) async {
  final text = (overrideText ?? _messageController.text).trim();
  if (text.isEmpty || _isSending) return;
    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isUser: true,
          time: DateTime.now(),
        ),
      );
      _messages.add(
        _ChatMessage(
          text: "Analyzing...",
          isUser: false,
          time: DateTime.now(),
          isLoading: true,
        ),
      );
      _isSending = true;
    });
    _persistMessages();

    _messageController.clear();
    _scrollToBottom();

    try {
      final reply = await _getAssistantReply(text);

      if (!mounted) return;

      setState(() {
        _removeLastLoadingMessage();
        _messages.add(
          _ChatMessage(
            text: reply,
            isUser: false,
            time: DateTime.now(),
          ),
        );
      });
      _persistMessages();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _removeLastLoadingMessage();
        _messages.add(
          _ChatMessage(
            text: "Unable to reach the assistant right now.\n\nDetails: $e",
            isUser: false,
            time: DateTime.now(),
            isError: true,
          ),
        );
      });
      _persistMessages();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
      _scrollToBottom();
    }
  }

  void _removeLastLoadingMessage() {
    for (var i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isLoading) {
        _messages.removeAt(i);
        return;
      }
    }
  }

  String get _sessionKey => "$_sessionKeyPrefix${widget.doctorId}";

  void _loadSessionHistory() {
    final raw = SessionStorage.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      final restored = decoded
          .whereType<Map>()
          .map((e) => _ChatMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (restored.isEmpty) return;

      setState(() {
        _messages
          ..clear()
          ..addAll(restored);
      });
    } catch (_) {
      // Ignore session restore failures.
    }
  }

  void _persistMessages() {
    final payload = _messages
        .where((m) => !m.isLoading)
        .map((m) => m.toJson())
        .toList();

    SessionStorage.setString(_sessionKey, jsonEncode(payload));
  }

  Future<String> _getAssistantReply(String userMessage) async {
    final raw = await ApiService().orchestrate(
      id: "ClinicalReasoning",
      message: userMessage,
    );

    try {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) {
        if (data["reply"] != null) return data["reply"].toString();
        if (data["message"] != null) return data["message"].toString();
        if (data["content"] != null) return data["content"].toString();
        if (data["result"] != null) return data["result"].toString();
      }
    } catch (_) {
      // Non-JSON response, return raw string.
    }

    return raw;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _fillQuickPrompt(String text) {
    _messageController.text = text;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF2F7F6);
    const border = Color(0xFFE5E7EB);
    const primary = Color(0xFF1F6F8B);
    const accent = Color(0xFF2E9CA6);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: EdgeInsets.all(_pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Clinical Analysis",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Clinical reasoning and analysis assistant",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 18),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _QuickPromptChip(
                        label: "Chest Pain",
                        onTap: () => _fillQuickPrompt(
                          "Chest Pain.",
                        ),
                      ),
                      _QuickPromptChip(
                        label: "Stomach Ache",
                        onTap: () => _fillQuickPrompt(
                          "Stomach Ache.",
                        ),
                      ),
                      _QuickPromptChip(
                        label: "Breathing Problems",
                        onTap: () => _fillQuickPrompt(
                          "Breathing Problems.",
                        ),
                      ),
                      _QuickPromptChip(
                        label: "Cancer Screening",
                        onTap: () => _fillQuickPrompt(
                          "Cancer Screening.",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: border),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 42,
                                  width: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2F4),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.smart_toy_outlined,
                                    color: primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Clinical Analysis",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                      Text(
                                        "Doctor ID: ${widget.doctorId}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                return _ChatBubble(message: message);
                              },
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: border),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _messageController,
                                    minLines: 1,
                                    maxLines: 5,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => _sendMessage(),
                                    decoration: InputDecoration(
                                      hintText: "Ask for clinical analysis...",
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: border,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: border,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: accent,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 👇 only new widget
                                VoiceInputButton(
                                  sttService: _sttService,
                                  textController: _messageController,
                                  onTranscribed: (transcript) {
                                    _sendMessage(transcript); // 👈 pass directly, skip the controller
                                  },
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 52,
                                  width: 52,
                                  child: ElevatedButton(
                                    onPressed: _isSending ? null : _sendMessage,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1F6F8B),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: _isSending
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.send),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickPromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickPromptChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1F6F8B);
    const border = Color(0xFFE5E7EB);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 760),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF1F6F8B)
              : (message.isError
                  ? const Color(0xFFFFEBEE)
                  : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.isLoading)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Analyzing...",
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              )
            else
              Text(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : (message.isError
                          ? const Color(0xFFC62828)
                          : const Color(0xFF111827)),
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              _formatTime(message.time),
              style: TextStyle(
                fontSize: 11,
                color: isUser
                    ? Colors.white70
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final bool isError;
  final bool isLoading;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.isError = false,
    this.isLoading = false,
  });

  Map<String, dynamic> toJson() {
    return {
      "text": text,
      "isUser": isUser,
      "time": time.toIso8601String(),
      "isError": isError,
    };
  }

  static _ChatMessage fromJson(Map<String, dynamic> json) {
    return _ChatMessage(
      text: json["text"]?.toString() ?? "",
      isUser: json["isUser"] == true,
      time: DateTime.tryParse(json["time"]?.toString() ?? "") ??
          DateTime.now(),
      isError: json["isError"] == true,
    );
  }
}