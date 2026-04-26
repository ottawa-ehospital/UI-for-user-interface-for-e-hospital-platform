import 'dart:convert';

class MessageParticipant {
  final int? id;
  final String type;
  final String name;

  const MessageParticipant({
    required this.id,
    required this.type,
    required this.name,
  });



  factory MessageParticipant.fromJson(Map<String, dynamic> json) {
    return MessageParticipant(
      id: _toInt(
        json['id'] ??
            json['user_id'] ??
            json['patient_id'] ??
            json['doctor_id'] ??
            json['staff_id'],
      ),
      type: _toStr(json['type']),
      name: _toStr(
        json['name'] ??
            [
              _toStr(json['FName']),
              _toStr(json['LName']),
            ].where((e) => e.isNotEmpty).join(' '),
      ),
    );
  }
}

class MessageItem {
  final int messageId;
  final String subject;
  final String content;
  final String contentPlain;
  final DateTime? timestamp;
  final bool readStatus;
  final String senderType;

  const MessageItem({
    required this.messageId,
    required this.subject,
    required this.content,
    required this.contentPlain,
    required this.timestamp,
    required this.readStatus,
    required this.senderType,
  });

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      messageId: _toInt(json['message_id']) ?? 0,
      subject: _toStr(json['subject']),
      content: _toStr(json['content']),
      contentPlain: _toStr(json['content_plain']),
      timestamp: _toDateTime(json['timestamp']),
      readStatus: _toBool(json['read_status']),
      senderType: _toStr(json['sender_type']),
    );
  }

  String get displayContent {
    if (contentPlain.trim().isNotEmpty) return contentPlain.trim();
    return content.trim();
  }
}
class ThreadMessage {
  final MessageItem message;
  final bool isOwn;

  const ThreadMessage({
    required this.message,
    required this.isOwn,
  });
}

class MessageConversation {
  final String category;
  final int conversationId;
  final String participantName;
  final int? participantId;
  final List<MessageParticipant> participants;
  final Map<String, List<MessageParticipant>> viewerPermissions;
  final List<MessageItem> send;
  final List<MessageItem> receive;
  final Map<String, List<MessageItem>> messagesBySenderType;

  const MessageConversation({
    required this.category,
    required this.conversationId,
    required this.participantName,
    required this.participantId,
    required this.participants,
    required this.viewerPermissions,
    required this.send,
    required this.receive,
    required this.messagesBySenderType,
  });

  factory MessageConversation.fromJson(
    Map<String, dynamic> json, {
    required String category,
  }) {
    final rawParticipants = json['participants'];
    final participants = <MessageParticipant>[];
    if (rawParticipants is List) {
      for (final item in rawParticipants) {
        if (item is Map) {
          participants.add(
            MessageParticipant.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final rawViewerPermissions = json['viewer_permissions'];
    final viewerPermissions = <String, List<MessageParticipant>>{};
    if (rawViewerPermissions is Map) {
      for (final entry in rawViewerPermissions.entries) {
        final value = entry.value;
        if (value is List) {
          viewerPermissions[entry.key] = value
              .whereType<Map>()
              .map((e) => MessageParticipant.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else {
          viewerPermissions[entry.key] = const [];
        }
      }
    }

    final send = <MessageItem>[];
    if (json['send'] is List) {
      for (final item in json['send']) {
        if (item is Map) {
          send.add(MessageItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final receive = <MessageItem>[];
    if (json['receive'] is List) {
      for (final item in json['receive']) {
        if (item is Map) {
          receive.add(MessageItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final messagesBySenderType = <String, List<MessageItem>>{};
    final rawGrouped = json['messages_by_sender_type'];
    if (rawGrouped is Map) {
      for (final entry in rawGrouped.entries) {
        final value = entry.value;
        if (value is List) {
          messagesBySenderType[entry.key] = value
              .whereType<Map>()
              .map((e) => MessageItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else {
          messagesBySenderType[entry.key] = const [];
        }
      }
    }

    return MessageConversation(
      category: category,
      conversationId: _toInt(json['conversation_id']) ?? 0,
      participantName: _toStr(json['participant_name']),
      participantId: _toInt(json['participant_id']),
      participants: participants,
      viewerPermissions: viewerPermissions,
      send: send,
      receive: receive,
      messagesBySenderType: messagesBySenderType,
    );
  }

  bool get isReadOnly => category.trim().toLowerCase() == 'read only';

  String get displayName {
    if (isReadOnly && participants.isNotEmpty) {
      return participants
          .map((p) => '${p.type.isEmpty ? 'User' : p.type} ${p.name}'.trim())
          .join(', ');
    }
    if (participantName.trim().isNotEmpty) return participantName.trim();
    return 'Unnamed Conversation';
  }

  String get viewerSummary {
    if (viewerPermissions.isEmpty) return 'No viewers';
    final chunks = <String>[];
    viewerPermissions.forEach((type, viewers) {
      chunks.add('${viewers.length} $type(s)');
    });
    return 'Visible to: ${chunks.join(', ')}';
  }

  String get viewerDetails {
    if (viewerPermissions.isEmpty) return 'No viewers';
    final chunks = <String>[];
    viewerPermissions.forEach((type, viewers) {
      final names = viewers.map((e) => e.name).where((e) => e.isNotEmpty).join(', ');
      chunks.add('$type(s): ${names.isEmpty ? 'No users' : names}');
    });
    return chunks.join('  •  ');
  }

  List<MessageItem> mergedMessages() {
    final merged = <MessageItem>[];

    if (isReadOnly) {
      messagesBySenderType.forEach((_, msgs) {
        merged.addAll(msgs);
      });
    } else {
      merged.addAll(send);
      merged.addAll(receive);
    }

    merged.sort((a, b) {
      final aTime = a.timestamp?.millisecondsSinceEpoch ?? 0;
      final bTime = b.timestamp?.millisecondsSinceEpoch ?? 0;
      return aTime.compareTo(bTime);
    });

    return merged;
  }

  List<ThreadMessage> mergedThreadMessages() {
    final merged = <ThreadMessage>[];

    if (isReadOnly) {
      messagesBySenderType.forEach((_, msgs) {
        for (final item in msgs) {
          merged.add(ThreadMessage(message: item, isOwn: false));
        }
      });
    } else {
      for (final item in send) {
        merged.add(ThreadMessage(message: item, isOwn: true));
      }
      for (final item in receive) {
        merged.add(ThreadMessage(message: item, isOwn: false));
      }
    }

    merged.sort((a, b) {
      final aTime = a.message.timestamp?.millisecondsSinceEpoch ?? 0;
      final bTime = b.message.timestamp?.millisecondsSinceEpoch ?? 0;
      return aTime.compareTo(bTime);
    });

    return merged;
  }

  List<int> unreadIncomingIdsFor(String currentUserType) {
    if (isReadOnly) return const [];
    return receive
        .where((m) => !m.readStatus)
        .map((m) => m.messageId)
        .where((id) => id > 0)
        .toList();
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}

String _toStr(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is List || value is Map) return jsonEncode(value);
  return value.toString();
}

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value != 0;
  final text = value.toString().trim().toLowerCase();
  return text == 'true' || text == '1';
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}