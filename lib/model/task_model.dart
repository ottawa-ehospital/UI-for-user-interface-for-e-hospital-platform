import 'package:flutter/material.dart';

class TaskModel {
  final String id;
  final String title;
  final TaskPriority priority;
  final DateTime? date;
  final TimeOfDay? time;
  final String description;

  TaskModel({
    required this.id,
    required this.title,
    required this.priority,
    this.date,
    this.time,
    required this.description,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    TaskPriority? priority,
    DateTime? date,
    TimeOfDay? time,
    String? description,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      date: date ?? this.date,
      time: time ?? this.time,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'priority': priority.name,
      'date': date?.toIso8601String(),
      'time': time != null ? '${time!.hour}:${time!.minute}' : null,
      'description': description,
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    TimeOfDay? timeOfDay;
    if (json['time'] != null) {
      final parts = (json['time'] as String).split(':');
      timeOfDay = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    return TaskModel(
      id: json['id'],
      title: json['title'],
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
      ),
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      time: timeOfDay,
      description: json['description'],
    );
  }
}

enum TaskPriority {
  high,
  medium,
  low,
  none;

  String get displayName {
    switch (this) {
      case TaskPriority.high:
        return 'High Priority';
      case TaskPriority.medium:
        return 'Medium Priority';
      case TaskPriority.low:
        return 'Low Priority';
      case TaskPriority.none:
        return 'No Priority';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.high:
        return const Color(0xFFEF4444); // Red
      case TaskPriority.medium:
        return const Color(0xFF10B981); // Green
      case TaskPriority.low:
        return const Color(0xFFF59E0B); // Yellow
      case TaskPriority.none:
        return const Color(0xFF9CA3AF); // Gray
    }
  }
}
