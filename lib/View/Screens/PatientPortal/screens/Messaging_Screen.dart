import 'package:ehosptal_flutter_revamp/Service/API_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MessagingScreen — Patient portal messaging
//
//  DB model (no thread abstraction):
//    message_pat_to_doctor / message_doctor_to_pat       → "Doctor" tab
//    message_pat_to_clinicalstaff / message_clinicalstaff_to_pat → "ClinicStaff" tab
//
//  Left panel  : category tabs + contact list
//  Right panel : merged chronological messages + reply bar
//  Compose     : full-screen new message form
// ─────────────────────────────────────────────────────────────────────────────

class MessagingScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  const MessagingScreen({super.key, required this.patient});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  static const Color _primary = Color(0xFF3F51B5);
  static const Color _bg = Color(0xFFF5F7FB);

  final ApiService _api = ApiService();

  // ── category ───────────────────────────────────────────────────────────────
  String _activeCategory = 'Doctor';

  // ── partner list ───────────────────────────────────────────────────────────
  bool _loadingPartners = true;
  String? _partnersError;
  List<Map<String, dynamic>> _partners = [];

  // ── active conversation ────────────────────────────────────────────────────
  Map<String, dynamic>? _activePartner;
  bool _loadingMessages = false;
  String? _messagesError;
  List<Map<String, dynamic>> _messages = [];

  // ── search ─────────────────────────────────────────────────────────────────
  String _searchQuery = '';

  // ── reply ──────────────────────────────────────────────────────────────────
  final TextEditingController _replyController = TextEditingController();
  bool _sendingReply = false;
  bool _replyUrgent = false;
  final ScrollController _messageScroll = ScrollController();

  // ── compose ────────────────────────────────────────────────────────────────
  bool _showCompose = false;
  String _composeCategory = 'Doctor';
  final TextEditingController _composeController = TextEditingController();
  bool _composeUrgent = false;
  bool _sendingCompose = false;
  bool _loadingRecipients = false;
  List<Map<String, dynamic>> _availableRecipients = [];
  Map<String, dynamic>? _selectedRecipient;
  String _recipientSearch = '';

  // ── mobile nav ─────────────────────────────────────────────────────────────
  int _mobilePane = 0; // 0 = list, 1 = conversation

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _composeController.dispose();
    _messageScroll.dispose();
    super.dispose();
  }

  dynamic get _patientId => widget.patient['id'] ?? widget.patient['patientId'];

  // ─────────────────────────────── DATA ─────────────────────────────────────

Future<void> _loadPartners() async {
    setState(() { _loadingPartners = true; _partnersError = null; _partners = []; });
    try {
      final conversations = await _api.getPatientConversations(patientId: _patientId);
      final categoryConvs = conversations[_activeCategory] ?? [];

      final normalised = categoryConvs.map((c) {
        // conversation_id, partner_name, partner_id, last_message, last_time, unread
        final id = c['partner_id'] ?? c['receiver_id'] ?? c['sender_id'] ?? c['conversation_id'];
        final rawName = (c['partner_name'] ?? c['receiver_name'] ?? c['sender_name'] ?? '').toString();
        final name = rawName.isNotEmpty ? rawName
            : '${c['Fname'] ?? c['FName'] ?? ''} ${c['Lname'] ?? c['LName'] ?? ''}'.trim();
        return {
          'id':            id,
          'conversation_id': c['conversation_id'],
          'name':          name.isNotEmpty ? name : 'Unknown',
          'subtitle':      (c['specialty'] ?? c['role'] ?? c['subject'] ?? '').toString(),
          'lastMessage':   (c['last_message'] ?? c['content'] ?? c['subject'] ?? '').toString(),
          'lastSentAt':    c['last_time'] ?? c['sent_at'] ?? c['time_stamp'],
          'unread':        c['unread'] == true || (c['unread_count'] ?? 0) > 0,
        };
      }).toList();

      setState(() { _partners = normalised; _loadingPartners = false; });
    } catch (e) {
      setState(() { _loadingPartners = false; _partnersError = e.toString(); });
    }
  }

  Future<void> _openConversation(Map<String, dynamic> partner) async {
    setState(() {
      _activePartner = partner;
      _loadingMessages = true;
      _messagesError = null;
      _messages = [];
      _mobilePane = 1;
    });
    try {
      // Reload full conversations to get messages for this conversation
      final conversations = await _api.getPatientConversations(patientId: _patientId);
      final categoryConvs = conversations[_activeCategory] ?? [];
      final conv = categoryConvs.firstWhere(
        (c) => (c['conversation_id'] ?? c['partner_id']) == (partner['conversation_id'] ?? partner['id']),
        orElse: () => <String, dynamic>{},
      );

      final rawMessages = conv['messages'] as List? ?? [];
      final normalised = rawMessages.map((m) {
        final mm = m is Map ? Map<String, dynamic>.from(m) : <String, dynamic>{};
        final senderType = (mm['sender_type'] ?? mm['senderType'] ?? '').toString();
        return {
          'messageId':  mm['message_id'] ?? mm['id'],
          'senderRole': senderType.isNotEmpty ? senderType : _inferRole(mm),
          'message':    (mm['content'] ?? mm['message'] ?? mm['body'] ?? '').toString(),
          'sent_at':    mm['sent_at'] ?? mm['time_stamp'] ?? mm['timestamp'] ?? mm['created_at'],
          'is_urgent':  mm['is_urgent'] == 1 || mm['is_urgent'] == true,
        };
      }).toList();

      normalised.sort((a, b) {
        final ad = DateTime.tryParse((a['sent_at'] ?? '').toString());
        final bd = DateTime.tryParse((b['sent_at'] ?? '').toString());
        if (ad == null || bd == null) return 0;
        return ad.compareTo(bd);
      });

      setState(() { _messages = normalised; _loadingMessages = false; });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      setState(() { _loadingMessages = false; _messagesError = e.toString(); });
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _activePartner == null) return;
    setState(() => _sendingReply = true);
    try {
      await _api.sendMessage(
        senderId: _patientId,
        senderType: "Patient",
        receiverId: _activePartner!['id'],
        receiverType: _activeCategory,
        content: text,
        conversationId: _activePartner!['conversation_id'] ?? 0,
      );
      _replyController.clear();
      await _openConversation(_activePartner!);
    } catch (e) {
      _showSnack('Failed to send: $e');
    } finally {
      setState(() => _sendingReply = false);
    }
  }

  Future<void> _loadComposeRecipients() async {
    setState(() { _loadingRecipients = true; _availableRecipients = []; _selectedRecipient = null; });
    try {
      List<Map<String, dynamic>> raw;
      if (_composeCategory == 'Doctor') {
        raw = await _api.getAvailableDoctors(patientId: _patientId);
      } else {
        raw = await _api.getAvailableStaff(patientId: _patientId);
      }
      setState(() {
        _availableRecipients = raw.map((r) {
          // /findDoctorsByPatientId returns Fname/Lname/id
          // /findClinicStaffsByPatientId may return FName/LName or name
          final firstName = (r['Fname'] ?? r['FName'] ?? r['fname'] ?? '').toString();
          final lastName  = (r['Lname'] ?? r['LName'] ?? r['lname'] ?? '').toString();
          final fullName  = '$firstName $lastName'.trim();
          return {
            'id':       r['id'] ?? r['doctor_id'] ?? r['staff_id'],
            'name':     fullName.isNotEmpty ? fullName : (r['name'] ?? 'Unknown').toString(),
            'subtitle': (r['specialty'] ?? r['role'] ?? '').toString(),
          };
        }).toList();
        _loadingRecipients = false;
      });
    } catch (_) {
      setState(() => _loadingRecipients = false);
    }
  }

  Future<void> _sendCompose() async {
    final text = _composeController.text.trim();
    if (text.isEmpty || _selectedRecipient == null) {
      _showSnack('Please select a recipient and write a message.');
      return;
    }
    setState(() => _sendingCompose = true);
    try {
      await _api.sendMessage(
        senderId: _patientId,
        senderType: "Patient",
        receiverId: _selectedRecipient!['id'],
        receiverType: _composeCategory,
        content: text,
        subject: '',
        conversationId: 0,
      );
      _composeController.clear();
      setState(() {
        _showCompose = false;
        _selectedRecipient = null;
        _activeCategory = _composeCategory;
      });
      _showSnack('Message sent!');
      _loadPartners();
    } catch (e) {
      _showSnack('Failed to send: $e');
    } finally {
      setState(() => _sendingCompose = false);
    }
  }

  void _scrollToBottom() {
    if (_messageScroll.hasClients) {
      _messageScroll.animateTo(_messageScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─────────────────────────────── BUILD ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth >= 900;
      if (_showCompose) return _buildCompose();
      if (isDesktop) return _buildDesktopLayout();
      return _buildMobileLayout();
    });
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        SizedBox(width: 300, child: _buildLeftPanel()),
        const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE8EAF6)),
        Expanded(child: _buildConversationPanel()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    if (_mobilePane == 0) return _buildLeftPanel();
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _mobilePane = 0)),
              Expanded(
                child: Text(_activePartner?['name'] ?? 'Conversation',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildConversationPanel()),
      ],
    );
  }

  // ─────────────────────────── LEFT PANEL ───────────────────────────────────

  Widget _buildLeftPanel() {
    final filtered = _partners.where((p) {
      if (_searchQuery.isEmpty) return true;
      return (p['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: ElevatedButton.icon(
              onPressed: () {
                _composeCategory = _activeCategory;
                _loadComposeRecipients();
                setState(() => _showCompose = true);
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Send New Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              _categoryTile('Doctor'),
              _categoryTile('ClinicStaff'),
            ]),
          ),

          const Divider(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: _bg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _loadingPartners
                ? const Center(child: CircularProgressIndicator())
                : _partnersError != null
                    ? _errorWidget(_partnersError!, _loadPartners)
                    : filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'No ${_activeCategory == "Doctor" ? "doctors" : "staff"} found.',
                                style: const TextStyle(color: Colors.black45),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, i) => _partnerTile(filtered[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _categoryTile(String label) {
    final selected = _activeCategory == label;
    final display  = label == 'ClinicStaff' ? 'Clinic Staff' : label;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() {
          _activeCategory = label;
          _activePartner  = null;
          _messages       = [];
          _searchQuery    = '';
        });
        _loadPartners();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: selected
            ? BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(8))
            : null,
        child: Row(
          children: [
            Icon(Icons.person_outline, size: 20, color: selected ? _primary : Colors.grey[600]),
            const SizedBox(width: 10),
            Expanded(
              child: Text(display,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? _primary : Colors.grey[700],
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _partnerTile(Map<String, dynamic> partner) {
    final isActive  = _activePartner?['id'] == partner['id'];
    final name      = (partner['name'] ?? 'Unknown').toString();
    final subtitle  = (partner['subtitle'] ?? '').toString();
    final lastMsg   = (partner['lastMessage'] ?? '').toString();
    final ts        = _formatTime(partner['lastSentAt']);
    final unread    = partner['unread'] == true;

    return InkWell(
      onTap: () => _openConversation(partner),
      child: Container(
        color: isActive ? const Color(0xFFEEF0FA) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatar(name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 14,
                            )),
                      ),
                      if (ts.isNotEmpty)
                        Text(ts, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 11, color: Colors.black45),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (lastMsg.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: unread ? Colors.black87 : Colors.black54,
                          fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
                        )),
                  ],
                  if (unread) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                      child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── RIGHT PANEL ──────────────────────────────────

  Widget _buildConversationPanel() {
    if (_activePartner == null) {
      return Container(
        color: _bg,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mail_outline, size: 64, color: Colors.black26),
              SizedBox(height: 12),
              Text('Select a contact to view messages',
                  style: TextStyle(color: Colors.black45, fontSize: 15)),
            ],
          ),
        ),
      );
    }

    final name     = (_activePartner!['name'] ?? 'Unknown').toString();
    final subtitle = (_activePartner!['subtitle'] ?? '').toString();

    return Container(
      color: _bg,
      child: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                _avatar(name, radius: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle,
                            style: const TextStyle(
                                color: _primary, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.phone_outlined, color: Colors.black45)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.videocam_outlined, color: Colors.black45)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: Colors.black45)),
              ],
            ),
          ),

          const Divider(height: 1),

          // Messages
          Expanded(
            child: _loadingMessages
                ? const Center(child: CircularProgressIndicator())
                : _messagesError != null
                    ? _errorWidget(_messagesError!, () => _openConversation(_activePartner!))
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.black26),
                                const SizedBox(height: 12),
                                Text('No messages yet with $name.',
                                    style: const TextStyle(color: Colors.black45)),
                                const SizedBox(height: 8),
                                const Text('Send a message below to start the conversation.',
                                    style: TextStyle(color: Colors.black38, fontSize: 12)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _messageScroll,
                            padding: const EdgeInsets.all(20),
                            itemCount: _messages.length,
                            itemBuilder: (ctx, i) => _messageBubble(_messages[i]),
                          ),
          ),

          _buildReplyBar(),
        ],
      ),
    );
  }

  Widget _messageBubble(Map<String, dynamic> msg) {
    final senderRole    = (msg['senderRole'] ?? 'Patient').toString();
    final isFromPatient = senderRole.toLowerCase() == 'patient';
    final text          = (msg['message'] ?? '').toString();
    final ts            = _formatMessageTime(msg['sent_at']);
    final isUrgent      = msg['is_urgent'] == true;
    final partnerName   = (_activePartner?['name'] ?? 'Unknown').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isFromPatient ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromPatient) ...[
            _avatar(partnerName),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isFromPatient ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isFromPatient)
                      Text(partnerName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    if (isUrgent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                        child: const Text('URGENT',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                    if (ts.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(ts, style: const TextStyle(color: Colors.black45, fontSize: 11)),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isFromPatient ? const Color(0xFF3F51B5) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(12),
                      topRight:    const Radius.circular(12),
                      bottomLeft:  Radius.circular(isFromPatient ? 12 : 2),
                      bottomRight: Radius.circular(isFromPatient ? 2 : 12),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(text,
                      style: TextStyle(
                          fontSize: 14, height: 1.5,
                          color: isFromPatient ? Colors.white : Colors.black87)),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _reactionBtn(Icons.thumb_up_outlined),
                    _reactionBtn(Icons.star_border),
                    _reactionBtn(Icons.reply),
                  ],
                ),
              ],
            ),
          ),
          if (isFromPatient) ...[
            const SizedBox(width: 10),
            _avatar('Me', color: Colors.grey[400]!),
          ],
        ],
      ),
    );
  }

  Widget _reactionBtn(IconData icon) {
    return IconButton(
      iconSize: 16,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      onPressed: () {},
      icon: Icon(icon, color: Colors.black38),
    );
  }

  Widget _buildReplyBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _toolbarBtn(Icons.format_bold),
                _toolbarBtn(Icons.format_italic),
                _toolbarBtn(Icons.format_underline),
                _toolbarBtn(Icons.format_color_text),
                _toolbarBtn(Icons.format_strikethrough),
                _toolbarBtn(Icons.format_list_numbered),
                _toolbarBtn(Icons.format_list_bulleted),
                _toolbarBtn(Icons.format_align_left),
                _toolbarBtn(Icons.link),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _replyUrgent = !_replyUrgent),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _replyUrgent ? Colors.red[50] : Colors.transparent,
                      border: Border.all(color: _replyUrgent ? Colors.red : Colors.black26),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.priority_high, size: 14, color: _replyUrgent ? Colors.red : Colors.black45),
                        const SizedBox(width: 3),
                        Text('Urgent',
                            style: TextStyle(
                                fontSize: 11,
                                color: _replyUrgent ? Colors.red : Colors.black45,
                                fontWeight: _replyUrgent ? FontWeight.w700 : FontWeight.normal)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  maxLines: 4,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Type your message here...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _sendingReply
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : ElevatedButton.icon(
                      onPressed: _sendReply,
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('SEND'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                    ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Not monitored 24/7. For emergencies call 911.',
                style: const TextStyle(fontSize: 10, color: Colors.black38)),
          ),
        ],
      ),
    );
  }

  Widget _toolbarBtn(IconData icon) {
    return IconButton(
      iconSize: 18,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      onPressed: () {},
      icon: Icon(icon, color: Colors.black54),
    );
  }

  // ─────────────────────────── COMPOSE ──────────────────────────────────────

  Widget _buildCompose() {
    final filteredRecipients = _availableRecipients.where((r) {
      if (_recipientSearch.isEmpty) return true;
      return (r['name'] ?? '').toString().toLowerCase().contains(_recipientSearch.toLowerCase());
    }).toList();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('New Message',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(onPressed: () => setState(() => _showCompose = false), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 20),

          // To: row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: SizedBox(width: 64, child: Text('To:', style: TextStyle(fontWeight: FontWeight.w700))),
              ),
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.black26), borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _composeCategory,
                    items: const [
                      DropdownMenuItem(value: 'Doctor',     child: Text('Doctor')),
                      DropdownMenuItem(value: 'ClinicStaff', child: Text('Clinic Staff')),
                    ],
                    onChanged: (v) {
                      setState(() { _composeCategory = v!; _selectedRecipient = null; _recipientSearch = ''; });
                      _loadComposeRecipients();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      onChanged: (v) => setState(() => _recipientSearch = v),
                      decoration: InputDecoration(
                        hintText: _selectedRecipient != null
                            ? (_selectedRecipient!['name'] ?? 'Selected').toString()
                            : 'Search recipient...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: _selectedRecipient != null ? _primary : Colors.black26)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: _selectedRecipient != null ? _primary : Colors.black26)),
                        prefixIcon: _selectedRecipient != null
                            ? const Icon(Icons.check_circle, color: _primary, size: 18)
                            : const Icon(Icons.search, size: 18, color: Colors.black45),
                      ),
                    ),
                    if (_loadingRecipients)
                      const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))
                    else if (filteredRecipients.isNotEmpty && _selectedRecipient == null)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.1))],
                        ),
                        child: ListView(
                          shrinkWrap: true,
                          children: filteredRecipients.take(8).map((r) => ListTile(
                            leading: _avatar((r['name'] ?? '?').toString(), radius: 16),
                            title: Text((r['name'] ?? 'Unknown').toString(),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: (r['subtitle'] ?? '').toString().isNotEmpty
                                ? Text(r['subtitle'].toString(), style: const TextStyle(fontSize: 12))
                                : null,
                            onTap: () => setState(() { _selectedRecipient = r; _recipientSearch = ''; }),
                          )).toList(),
                        ),
                      ),
                    if (_selectedRecipient != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            _avatar((_selectedRecipient!['name'] ?? '').toString(), radius: 14),
                            const SizedBox(width: 8),
                            Text((_selectedRecipient!['name'] ?? '').toString(),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            if ((_selectedRecipient!['subtitle'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text('· ${_selectedRecipient!['subtitle']}',
                                  style: const TextStyle(color: Colors.black45, fontSize: 12)),
                            ],
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _selectedRecipient = null),
                              child: const Icon(Icons.cancel, size: 16, color: Colors.black45),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Urgent toggle
          Row(
            children: [
              const SizedBox(width: 64),
              GestureDetector(
                onTap: () => setState(() => _composeUrgent = !_composeUrgent),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _composeUrgent ? Colors.red[50] : Colors.transparent,
                    border: Border.all(color: _composeUrgent ? Colors.red : Colors.black26),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.priority_high, size: 16, color: _composeUrgent ? Colors.red : Colors.black45),
                      const SizedBox(width: 4),
                      Text('Mark as Urgent',
                          style: TextStyle(
                              fontSize: 13,
                              color: _composeUrgent ? Colors.red : Colors.black54,
                              fontWeight: _composeUrgent ? FontWeight.w700 : FontWeight.normal)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Formatting toolbar
          Wrap(
            spacing: 2,
            children: [
              _toolbarChip('H1'), _toolbarChip('H2'), _toolbarChip('Sans Serif'),
              _toolbarBtn(Icons.format_list_numbered), _toolbarBtn(Icons.format_list_bulleted),
              _toolbarBtn(Icons.format_align_left),    _toolbarBtn(Icons.format_bold),
              _toolbarBtn(Icons.format_italic),        _toolbarBtn(Icons.format_underline),
              _toolbarBtn(Icons.link),                 _toolbarBtn(Icons.format_color_text),
              _toolbarBtn(Icons.format_strikethrough), _toolbarBtn(Icons.format_quote),
              _toolbarBtn(Icons.code),
            ],
          ),

          const Divider(height: 16),

          // Body
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bg,
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: TextField(
                controller: _composeController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Write something awesome...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _showCompose = false),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                child: const Text('BACK'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _sendingCompose ? null : _sendCompose,
                icon: _sendingCompose
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, size: 18),
                label: const Text('SEND'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolbarChip(String label) {
    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  // ─────────────────────────── HELPERS ──────────────────────────────────────

  Widget _avatar(String name, {double radius = 18, Color? color}) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').map((w) => w[0].toUpperCase()).take(2).join();
    return CircleAvatar(
      radius: radius,
      backgroundColor: color ?? _primary,
      child: Text(initials,
          style: TextStyle(color: Colors.white, fontSize: radius * 0.72, fontWeight: FontWeight.w700)),
    );
  }

  Widget _errorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 10),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt  = DateTime.parse(raw.toString()).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return DateFormat('h:mm a').format(dt);
      }
      return DateFormat('MMM d').format(dt);
    } catch (_) { return ''; }
  }

  String _formatMessageTime(dynamic raw) {
    if (raw == null) return '';
    try {
      return DateFormat('MMM d, h:mm a').format(DateTime.parse(raw.toString()).toLocal());
    } catch (_) { return ''; }
  }
}

  String _inferRole(Map<String, dynamic> m) {
    if (m.containsKey('doctor_id') && !m.containsKey('patient_id')) return 'Doctor';
    if (m.containsKey('sender_id')) return 'ClinicStaff';
    return 'Patient';
  }