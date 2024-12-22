import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/emoji_repository.dart';
import '../../data/models/category.dart';
import '../../data/models/emoji.dart';
import '../utils/error_manager.dart';
import 'package:flutter/material.dart' show IconData;
import '../../providers/app_provider.dart'
    show categoriesProvider, emojisProvider, backupHistoryProvider;

class SyncData {
  final List<Category> categories;
  final List<Emoji> emojis;
  final DateTime timestamp;

  SyncData({
    required this.categories,
    required this.emojis,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'categories': categories.map((c) => c.toJson()).toList(),
        'emojis': emojis.map((e) => e.toJson()).toList(),
        'timestamp': timestamp.toIso8601String(),
      };

  factory SyncData.fromJson(Map<String, dynamic> json) {
    return SyncData(
      categories: (json['categories'] as List)
          .map((c) => Category.fromJson(c))
          .toList(),
      emojis: (json['emojis'] as List).map((e) => Emoji.fromJson(e)).toList(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

final syncManagerProvider = Provider((ref) => SyncManager(ref));

class BackupHistory {
  final String path;
  final DateTime timestamp;
  final int categoryCount;
  final int emojiCount;
  final BackupType type;

  BackupHistory({
    required this.path,
    required this.timestamp,
    required this.categoryCount,
    required this.emojiCount,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'timestamp': timestamp.toIso8601String(),
        'categoryCount': categoryCount,
        'emojiCount': emojiCount,
        'type': type.name,
      };

  factory BackupHistory.fromJson(Map<String, dynamic> json) => BackupHistory(
        path: json['path'],
        timestamp: DateTime.parse(json['timestamp']),
        categoryCount: json['categoryCount'],
        emojiCount: json['emojiCount'],
        type: BackupType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => BackupType.export,
        ),
      );
}

enum BackupType {
  export,
  import,
}

class SyncManager {
  final Ref _ref;

  SyncManager(this._ref);

  Future<File> exportData() async {
    try {
      final categoryRepo = _ref.read(categoryRepositoryProvider);
      final emojiRepo = _ref.read(emojiRepositoryProvider);
      final appDir = await getApplicationDocumentsDirectory();

      // 获取所有数据
      final categories = await categoryRepo.getCategories(includeDeleted: true);
      final emojis = await emojiRepo.getEmojis();

      // 创建备份目录
      final backupDir = Directory('${appDir.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // 创建备份文件夹
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = '${backupDir.path}/backup_$timestamp';
      final backupFolder = Directory(backupPath);
      await backupFolder.create();
      final emojiBackupDir = Directory('$backupPath/emojis');
      await emojiBackupDir.create();

      print('创建备份目录: $backupPath');

      // 复制所有表情图片到备份文件夹
      final emojiBackups = <Emoji>[];
      for (var emoji in emojis) {
        // 修正源文件路径
        final sourceFile = File(emoji.path.startsWith('/')
            ? emoji.path
            : '${appDir.path}/${emoji.path}');
        print('处理表情: ${emoji.name}, 源文件: ${sourceFile.path}');

        if (await sourceFile.exists()) {
          final fileName = sourceFile.path.split('/').last;
          final targetPath = '$backupPath/emojis/$fileName';
          await sourceFile.copy(targetPath);
          print('复制成功: $targetPath');

          // 使用相对路径
          emojiBackups.add(emoji.copyWith(path: 'emojis/$fileName'));
        } else {
          print('源文件不存在: ${sourceFile.path}');
        }
      }

      // 创建备份数据
      final syncData = SyncData(
        categories: categories,
        emojis: emojiBackups,
        timestamp: DateTime.now(),
      );

      // 保存备份数据
      final backupFile = File('$backupPath/backup.json');
      await backupFile.writeAsString(jsonEncode(syncData.toJson()));
      print('保存备份文件: ${backupFile.path}');

      await addBackupHistory(backupFile, syncData);
      _ref.invalidate(backupHistoryProvider);
      return backupFile;
    } catch (e, stack) {
      _ref.read(errorProvider.notifier).setError('导出失败: $e', stack);
      rethrow;
    }
  }

  Future<void> importData(String jsonString) async {
    try {
      final data = SyncData.fromJson(jsonDecode(jsonString));
      final categoryRepo = _ref.read(categoryRepositoryProvider);
      final emojiRepo = _ref.read(emojiRepositoryProvider);
      final appDir = await getApplicationDocumentsDirectory();

      // 获取备份文件所在目录
      final histories = await getBackupHistory();
      final history = histories.firstWhere(
        (h) => h.path.contains('backup_'),
        orElse: () => throw Exception('找不到备份文件'),
      );
      final backupFile = File(history.path);
      final backupDir = backupFile.parent;

      print('备份目录: ${backupDir.path}');
      print('备份文件: ${backupFile.path}');

      // 准备表情目录
      final emojiDir = Directory('${appDir.path}/emojis');
      if (!await emojiDir.exists()) {
        await emojiDir.create(recursive: true);
      }

      // 清空现有数据
      await categoryRepo.deleteAllCategories();
      await emojiRepo.deleteAllEmojis();

      // 导入分类
      for (var category in data.categories) {
        await categoryRepo.addCategory(
          category.name,
          IconData(category.icon, fontFamily: 'MaterialIcons'),
          color: category.color,
        );
      }

      // 导入表情
      for (var emoji in data.emojis) {
        try {
          final sourceFile = File('${backupDir.path}/${emoji.path}');
          print('处理表情: ${emoji.name}, 源文件: ${sourceFile.path}');

          if (await sourceFile.exists()) {
            final fileName = sourceFile.path.split('/').last;
            final targetPath = '${emojiDir.path}/$fileName';

            // 复制图片文件
            await sourceFile.copy(targetPath);
            print('复制成功: $targetPath');

            // 创建表情记录
            final newEmoji = await emojiRepo.addEmoji(
              name: emoji.name,
              path: 'emojis/$fileName',
              categoryId: emoji.categoryId,
            );

            if (newEmoji != null) {
              print('记录创建成功: ${newEmoji.name}, 路径: ${newEmoji.path}');
            } else {
              print('记录创建失败: ${emoji.name}');
            }
          } else {
            print('源文件不存在: ${sourceFile.path}');
          }
        } catch (e) {
          print('处理表情失败: ${emoji.name}, 错误: $e');
        }
      }

      // 刷新状态
      _ref.invalidate(categoriesProvider);
      _ref.invalidate(emojisProvider);
      _ref.invalidate(backupHistoryProvider);
    } catch (e, stack) {
      _ref.read(errorProvider.notifier).setError('导入失败: $e', stack);
      rethrow;
    }
  }

  Future<List<BackupHistory>> getBackupHistory() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final historyFile = File('${dir.path}/backup_history.json');

      if (!await historyFile.exists()) {
        return [];
      }

      final jsonString = await historyFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => BackupHistory.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addBackupHistory(File backupFile, SyncData data) async {
    await _addHistory(backupFile, data, BackupType.export);
  }

  Future<void> addImportHistory(File backupFile, SyncData data) async {
    await _addHistory(backupFile, data, BackupType.import);
  }

  Future<void> _addHistory(
      File backupFile, SyncData data, BackupType type) async {
    try {
      final history = BackupHistory(
        path: backupFile.path,
        timestamp: DateTime.now(),
        categoryCount: data.categories.length,
        emojiCount: data.emojis.length,
        type: type,
      );

      final dir = await getApplicationDocumentsDirectory();
      final historyFile = File('${dir.path}/backup_history.json');

      List<BackupHistory> histories = await getBackupHistory();
      histories.insert(0, history);

      // 每种类型只保留最近10条记录
      histories = _filterHistories(histories);

      await historyFile.writeAsString(
        jsonEncode(histories.map((h) => h.toJson()).toList()),
      );

      // 刷新备份历史
      _ref.invalidate(backupHistoryProvider);
    } catch (e) {
      print('Error adding backup history: $e');
    }
  }

  List<BackupHistory> _filterHistories(List<BackupHistory> histories) {
    final exports =
        histories.where((h) => h.type == BackupType.export).take(10);
    final imports =
        histories.where((h) => h.type == BackupType.import).take(10);
    return [...exports, ...imports]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // 删除单条历史记录
  Future<void> deleteBackupHistory(String path) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final historyFile = File('${dir.path}/backup_history.json');

      // 删除备份文件
      try {
        final backupFile = File(path);
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
      } catch (e) {
        print('Error deleting backup file: $path, error: $e');
      }

      // 更新历史记录
      List<BackupHistory> histories = await getBackupHistory();
      histories.removeWhere((h) => h.path == path);

      await historyFile.writeAsString(
        jsonEncode(histories.map((h) => h.toJson()).toList()),
      );
    } catch (e) {
      print('Error deleting backup history: $e');
    }
  }

  // 清空所有历史记录
  Future<void> clearBackupHistory() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final historyFile = File('${dir.path}/backup_history.json');

      // 先获取所有历史记录
      final histories = await getBackupHistory();

      // 删除所有备份文件
      for (var history in histories) {
        try {
          final backupFile = File(history.path);
          if (await backupFile.exists()) {
            await backupFile.delete();
          }
        } catch (e) {
          print('Error deleting backup file: ${history.path}, error: $e');
        }
      }

      // 清空历史记录
      await historyFile.writeAsString('[]');
    } catch (e) {
      print('Error clearing backup history: $e');
    }
  }
}
