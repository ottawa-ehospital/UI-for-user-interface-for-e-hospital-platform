import 'package:ehosptal_flutter_revamp/Service/API_service.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/Send_New_Message_Screen.dart';
import 'package:ehosptal_flutter_revamp/model/message_models.dart';
import 'package:flutter/material.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/Login_Screen.dart';

class MessagesScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const MessagesScreen({
    super.key,
    required this.doctor,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _messageScrollController = ScrollController();

  bool _loading = true;
  bool _sendingReply = false;
  String? _error;

  Map<String, List<MessageConversation>> _labels = {};
  String _selectedCategory = '';
  MessageConversation? _selectedConversation;

  dynamic get _doctorId {
    return widget.doctor['id'] ??
        widget.doctor['doctorId'] ??
        widget.doctor['doctor_id'] ??
        widget.doctor['user_id'] ??
        widget.doctor['userId'];
  }
  dynamic get _doctorIdForRequest {
    final raw = _doctorId;
    if (raw is int) return raw;
    final parsed = int.tryParse(raw?.toString() ?? '');
    return parsed ?? raw;
  }
  String get _currentUserType {
    final raw = (widget.doctor['type'] ?? 'Doctor').toString().trim();
    final lower = raw.toLowerCase();
    if (lower.contains('doctor')) return 'Doctor';
    if (lower.contains('patient')) return 'Patient';
    if (lower.contains('clinicstaff') || lower.contains('staff')) {
      return 'ClinicStaff';
    }
    return 'Doctor';
  }
  String get _currentUserName {
    String _readField(dynamic value) => value?.toString().trim() ?? '';

    final direct = _readField(
          widget.doctor['name'] ??
              widget.doctor['fullName'] ??
              widget.doctor['DoctorName'],
        )
        .trim();
    if (direct.isNotEmpty) return direct;

    final first = _readField(
      widget.doctor['FName'] ??
          widget.doctor['Fname'] ??
          widget.doctor['first_name'] ??
          widget.doctor['firstName'],
    );
    final last = _readField(
      widget.doctor['LName'] ??
          widget.doctor['Lname'] ??
          widget.doctor['last_name'] ??
          widget.doctor['lastName'],
    );
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;

    final email = _readField(
      widget.doctor['EmailId'] ?? widget.doctor['email'],
    );
    if (email.isNotEmpty) return email;

    final idText = _readField(widget.doctor['id']);
    return idText.isNotEmpty ? idText : 'You';
  }

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _searchController.dispose();
    _messageScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool showLoading = true}) async {
    final previousCategory = _selectedCategory;
    final previousConversationId = _selectedConversation?.conversationId;

    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      _error = null;
    }

    try {
      final labels = await _api.getMessagesByTypeAndId(
        userId: _doctorIdForRequest,
        userType: _currentUserType,
      );

      final categories = labels.keys.toList();
      String nextCategory = previousCategory;

      if (nextCategory.isEmpty || !labels.containsKey(nextCategory)) {
        nextCategory = categories.isNotEmpty ? categories.first : '';
      }

      MessageConversation? nextConversation;
      final listForCategory = labels[nextCategory] ?? [];

      if (previousConversationId != null) {
        try {
          nextConversation = listForCategory.firstWhere(
            (c) => c.conversationId == previousConversationId,
          );
        } catch (_) {
          nextConversation = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _labels = labels;
        _selectedCategory = nextCategory;
        _selectedConversation = nextConversation;
        _loading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openConversation(MessageConversation conversation) async {
    setState(() {
      _selectedConversation = conversation;
    });

    if (!conversation.isReadOnly) {
      final unreadIds = conversation.unreadIncomingIdsFor(_currentUserType);
      if (unreadIds.isNotEmpty) {
        try {
          await _api.messageReadStatusUpdate(messageIds: unreadIds);
          await _fetchMessages(showLoading: false);
        } catch (_) {
          // keep UI usable even if read-status call fails
        }
      }
    }

    _scrollToBottom();
  }

  Future<void> _sendReply() async {
    final conversation = _selectedConversation;
    if (conversation == null) return;
    if (conversation.isReadOnly) return;

    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sendingReply = true);

    try {
      final messages = conversation.mergedMessages();
      final lastSubject = messages.isNotEmpty && messages.last.subject.trim().isNotEmpty
          ? messages.last.subject.trim()
          : 'Untitled';

      final result = await _api.messageSend(
        payload: {
          "conversationId": conversation.conversationId,
          "senderType": _currentUserType,
          "sender_id": _doctorId,
          "receiverType": _selectedCategory,
          "receiver_id": conversation.participantId,
          "viewer_permissions": _viewerPermissionsToJson(conversation),
          "subject": "Re: $lastSubject",
          "content": text,
        },
      );

      if (!mounted) return;
      setState(() => _sendingReply = false);

      if (result == 1) {
        _replyController.clear();
        await _fetchMessages(showLoading: false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply sent successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send reply.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sendingReply = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reply: $e')),
      );
    }
  }

  Future<void> _openCompose() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SendNewMessageScreen(doctor: widget.doctor),
      ),
    );

    if (result == true) {
      await _fetchMessages();
    }
  }

  List<MessageConversation> _filteredConversations() {
    final list = _labels[_selectedCategory] ?? [];
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return list;

    return list.where((conversation) {
      return conversation.displayName.toLowerCase().contains(query);
    }).toList();
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _selectedConversation = null;
      _searchController.clear();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messageScrollController.hasClients) return;
      _messageScrollController.animateTo(
        _messageScrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF5F7FB);
    const border = Color(0xFFE5E7EB);
    const primary = Color(0xFF3F51B5);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 980;

            if (_loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load messages.\n\n$_error',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (isMobile) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Messages',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _openCompose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('New'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory.isEmpty ? null : _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _labels.keys
                          .map(
                            (key) => DropdownMenuItem<String>(
                              value: key,
                              child: Text('$key (${(_labels[key] ?? []).length})'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        _selectCategory(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedConversation == null)
                    Expanded(child: _buildConversationCard())
                  else
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() => _selectedConversation = null);
                                },
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Back to conversations'),
                              ),
                            ),
                          ),
                          Expanded(child: _buildDetailsCard()),
                        ],
                      ),
                    ),
                ],
              );
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  SizedBox(
                    width: 230,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Messages',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _openCompose,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Send New Message'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.all(10),
                              children: _labels.entries.map((entry) {
                                final selected = entry.key == _selectedCategory;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _selectCategory(entry.key),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? const Color(0xFFE8EAF6)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.mail_outline,
                                            color: selected ? primary : Colors.grey,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              entry.key,
                                              style: TextStyle(
                                                fontWeight: selected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: selected
                                                    ? primary
                                                    : const Color(0xFF111827),
                                              ),
                                            ),
                                          ),
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: selected
                                                ? primary
                                                : Colors.grey.shade200,
                                            child: Text(
                                              '${entry.value.length}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: selected
                                                    ? Colors.white
                                                    : const Color(0xFF111827),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 340,
                    child: _buildConversationCard(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDetailsCard(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildConversationCard() {
    const border = Color(0xFFE5E7EB);
    final conversations = _filteredConversations();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 0, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCategory.isEmpty
                      ? 'Conversations'
                      : '$_selectedCategory Messages',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: conversations.isEmpty
                ? const Center(
                    child: Text(
                      'No conversations in this category.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final messages = conversation.mergedThreadMessages();
                      final hasUnread = !conversation.isReadOnly &&
                          conversation.receive.any((m) => !m.readStatus);
                      final isSelected =
                          _selectedConversation?.conversationId == conversation.conversationId &&
                              _selectedConversation?.category == conversation.category;

                      return InkWell(
                        onTap: () => _openConversation(conversation),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF3F4F6)
                                : Colors.transparent,
                            border: const Border(
                              bottom: BorderSide(color: border),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFFE8EAF6),
                                foregroundColor: const Color(0xFF3F51B5),
                                child: Text(
                                  conversation.displayName.isEmpty
                                      ? 'U'
                                      : conversation.displayName[0].toUpperCase(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      conversation.displayName,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: const Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      conversation.viewerSummary,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    if (messages.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        _plainText(messages.last.message.displayContent),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (hasUnread)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  height: 10,
                                  width: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00BFFF),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    const border = Color(0xFFE5E7EB);
    const primary = Color(0xFF3F51B5);

    final conversation = _selectedConversation;
    if (conversation == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Select a conversation to view details.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final messages = conversation.mergedThreadMessages();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE8EAF6),
                  foregroundColor: primary,
                  child: Text(
                    conversation.displayName.isEmpty
                        ? 'U'
                        : conversation.displayName[0].toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conversation.viewerDetails,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
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
              controller: _messageScrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final threadMessage = messages[index];
                final message = threadMessage.message;
                final isOwn = !conversation.isReadOnly && threadMessage.isOwn;

                final senderName = conversation.isReadOnly
                  ? (message.senderType.toLowerCase() ==
                      _currentUserType.toLowerCase()
                    ? _currentUserName
                    : (message.senderType.isEmpty
                      ? 'Unknown Sender'
                      : message.senderType))
                  : (isOwn ? _currentUserName : conversation.displayName);

                return Align(
                  alignment: conversation.isReadOnly
                      ? Alignment.centerLeft
                      : (isOwn ? Alignment.centerRight : Alignment.centerLeft),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    constraints: const BoxConstraints(maxWidth: 650),
                    decoration: BoxDecoration(
                      color: conversation.isReadOnly
                          ? const Color(0xFFF3F4F6)
                          : (isOwn
                              ? const Color(0xFF3F51B5)
                              : const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: conversation.isReadOnly
                          ? CrossAxisAlignment.start
                          : (isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start),
                      children: [
                        Text(
                          senderName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: conversation.isReadOnly
                                ? const Color(0xFF111827)
                                : (isOwn ? Colors.white : const Color(0xFF111827)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: conversation.isReadOnly
                                ? Colors.grey.shade600
                                : (isOwn ? Colors.white70 : Colors.grey.shade600),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _plainText(message.displayContent),
                          style: TextStyle(
                            height: 1.4,
                            color: conversation.isReadOnly
                                ? const Color(0xFF111827)
                                : (isOwn ? Colors.white : const Color(0xFF111827)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (!conversation.isReadOnly)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: border)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _replyController,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: 'Write your reply...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _sendingReply ? null : _sendReply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                        ),
                        icon: _sendingReply
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: const Text('Send'),
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

  Map<String, dynamic> _viewerPermissionsToJson(MessageConversation conversation) {
    final result = <String, dynamic>{};
    conversation.viewerPermissions.forEach((key, value) {
      result[key] = value
          .map(
            (p) => {
              'id': p.id,
              'name': p.name,
            },
          )
          .toList();
    });
    return result;
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Unknown time';

    final local = value.toLocal();
    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final amPm = local.hour >= 12 ? 'PM' : 'AM';
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    return '$day/$month/$year $hour:$minute $amPm';
  }

  static String _plainText(String input) {
    if (input.trim().isEmpty) return 'No content';

    var text = input;

    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"');

    return text.trim().isEmpty ? 'No content' : text.trim();
  }
}