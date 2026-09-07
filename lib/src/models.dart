// Константы и модели мобильной CRM (зеркало десктопной версии).

import 'package:flutter/material.dart';

/// Статусы контактов.
class Status {
  static const String all = 'Все';
  static const String newContact = 'Новый';
  static const String call = 'Созвон';
  static const String meeting = 'Встреча';
  static const String signed = 'Подписан';
  static const String deepSigned = 'Подписан в глубь';
  static const String rejected = 'Отказ';

  static const List<String> list = [
    newContact, call, meeting, signed, deepSigned, rejected,
  ];

  static const List<String> filters = [all, ...list];
}

/// Результаты касаний и правила автообновления статуса.
class TouchResult {
  static const String signed = 'Подписался';
  static const String deepSigned = 'Подписался в глубь';
  static const String notSigned = 'Не подписался';
  static const String postponed = 'Перенесено';
  static const List<String> list = [
    '', signed, deepSigned, notSigned, postponed,
  ];
}

/// Модель контакта.
class Contact {
  final int? id;
  final String name;
  final String phone;
  final String tgPhone;
  final String vk;
  final String instagram;
  final String max;
  final String status;
  final String createdAt;

  const Contact({
    this.id,
    required this.name,
    this.phone = '',
    this.tgPhone = '',
    this.vk = '',
    this.instagram = '',
    this.max = '',
    this.status = Status.newContact,
    required this.createdAt,
  });

  Contact copyWith({
    int? id,
    String? name,
    String? phone,
    String? tgPhone,
    String? vk,
    String? instagram,
    String? max,
    String? status,
    String? createdAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      tgPhone: tgPhone ?? this.tgPhone,
      vk: vk ?? this.vk,
      instagram: instagram ?? this.instagram,
      max: max ?? this.max,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'tg_phone': tgPhone,
        'vk': vk,
        'instagram': instagram,
        'max': max,
        'status': status,
        'created_at': createdAt,
      };

  factory Contact.fromMap(Map<String, Object?> m) => Contact(
        id: m['id'] as int?,
        name: (m['name'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
        tgPhone: (m['tg_phone'] ?? '') as String,
        vk: (m['vk'] ?? '') as String,
        instagram: (m['instagram'] ?? '') as String,
        max: (m['max'] ?? '') as String,
        status: (m['status'] ?? Status.newContact) as String,
        createdAt: (m['created_at'] ?? '') as String,
      );
}

/// Модель касания.
class Touch {
  final int? id;
  final int contactId;
  final String touchType;
  final String result;
  final String? nextMeeting;
  final String agreement;
  final String comment;
  final String date;

  const Touch({
    this.id,
    required this.contactId,
    required this.touchType,
    this.result = '',
    this.nextMeeting,
    this.agreement = '',
    this.comment = '',
    required this.date,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'contact_id': contactId,
        'touch_type': touchType,
        'result': result,
        'next_meeting': nextMeeting,
        'agreement': agreement,
        'comment': comment,
        'date': date,
      };

  factory Touch.fromMap(Map<String, Object?> m) => Touch(
        id: m['id'] as int?,
        contactId: (m['contact_id'] as int?) ?? 0,
        touchType: (m['touch_type'] ?? '') as String,
        result: (m['result'] ?? '') as String,
        nextMeeting: m['next_meeting'] as String?,
        agreement: (m['agreement'] ?? '') as String,
        comment: (m['comment'] ?? '') as String,
        date: (m['date'] ?? '') as String,
      );
}

/// Цвета статусов (тёплая палитра приложения).
Color statusColor(String status) {
  switch (status) {
    case Status.signed:
      return const Color(0xFF7d8f4e);
    case Status.deepSigned:
      return const Color(0xFF6f8148);
    case Status.meeting:
      return const Color(0xFF8e9867);
    case Status.call:
      return const Color(0xFFe1937d);
    case Status.rejected:
      return const Color(0xFFc2654e);
    default:
      return const Color(0xFFa08a76);
  }
}
