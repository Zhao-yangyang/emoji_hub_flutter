class Emoji {
  final int? id;
  final String name;
  final String path;
  final int categoryId;
  final DateTime createTime;
  final DateTime updateTime;
  final bool isDeleted;

  Emoji({
    this.id,
    required this.name,
    required this.path,
    required this.categoryId,
    DateTime? createTime,
    DateTime? updateTime,
    this.isDeleted = false,
  })  : createTime = createTime ?? DateTime.now(),
        updateTime = updateTime ?? DateTime.now();

  // 从JSON转换
  factory Emoji.fromJson(Map<String, dynamic> json) {
    return Emoji(
      id: json['id'] as int?,
      name: json['name'] as String,
      path: json['path'] as String,
      categoryId: json['category_id'] as int,
      createTime: DateTime.parse(json['create_time'] as String),
      updateTime: DateTime.parse(json['update_time'] as String),
      isDeleted: (json['is_deleted'] as int) == 1,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'category_id': categoryId,
      'create_time': createTime.toIso8601String(),
      'update_time': updateTime.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  // 复制对象
  Emoji copyWith({
    int? id,
    String? name,
    String? path,
    int? categoryId,
    DateTime? createTime,
    DateTime? updateTime,
    bool? isDeleted,
  }) {
    return Emoji(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      categoryId: categoryId ?? this.categoryId,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
