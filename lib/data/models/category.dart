import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String name;
  final IconData icon;
  final int sortOrder;
  final DateTime createTime;
  final DateTime updateTime;
  final bool isDeleted;

  Category({
    this.id,
    required this.name,
    required this.icon,
    this.sortOrder = 0,
    DateTime? createTime,
    DateTime? updateTime,
    this.isDeleted = false,
  })  : createTime = createTime ?? DateTime.now(),
        updateTime = updateTime ?? DateTime.now();

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int?,
      name: json['name'] as String,
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      sortOrder: json['sort_order'] as int,
      createTime: DateTime.parse(json['create_time'] as String),
      updateTime: DateTime.parse(json['update_time'] as String),
      isDeleted: (json['is_deleted'] as int) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'sort_order': sortOrder,
      'create_time': createTime.toIso8601String(),
      'update_time': updateTime.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  Category copyWith({
    int? id,
    String? name,
    IconData? icon,
    int? sortOrder,
    DateTime? createTime,
    DateTime? updateTime,
    bool? isDeleted,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
