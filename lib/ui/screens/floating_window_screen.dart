import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'dart:io';
import '../../data/repositories/emoji_repository.dart';
import '../../data/models/emoji.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

class FloatingWindowScreen extends StatefulWidget {
  const FloatingWindowScreen({super.key});

  @override
  State<FloatingWindowScreen> createState() => _FloatingWindowScreenState();
}

class _FloatingWindowScreenState extends State<FloatingWindowScreen> {
  final _repository = EmojiRepository();
  List<Emoji> _emojis = [];
  bool _isLoading = true;
  String? _appDocPath;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      _appDocPath = appDocDir.path;
      await _loadEmojis();
    } catch (e) {
      print('初始化失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEmojis() async {
    try {
      final emojis = await _repository.getEmojis();
      print('加载到 ${emojis.length} 个表情');
      setState(() {
        _emojis = emojis;
        _isLoading = false;
      });
    } catch (e) {
      print('加载表情失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getFullPath(String relativePath) {
    if (_appDocPath == null) return relativePath;
    return path.join(_appDocPath!, relativePath);
  }

  Future<void> _shareEmoji(BuildContext context, Emoji emoji) async {
    final imagePath = _getFullPath(emoji.path);
    await _shareEmojiFile(imagePath);
  }

  Future<void> _shareEmojiFile(String imagePath) async {
    print('尝试分享图片: $imagePath');
    try {
      await Share.shareXFiles([XFile(imagePath)]);
      print('分享成功');
    } catch (e) {
      print('分享失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('构建悬浮窗界面, isLoading: $_isLoading, emojis数量: ${_emojis.length}');

    if (_isLoading) {
      return const Material(
        color: Colors.transparent,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_emojis.isEmpty) {
      return const Material(
        color: Colors.transparent,
        child: Center(
          child: Text('没有表情'),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        color: AppTheme.background,
        child: GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _emojis.length,
          itemBuilder: (context, index) {
            final emoji = _emojis[index];
            final imagePath = _getFullPath(emoji.path);

            return InkWell(
              onTap: () {
                print('点击表情: ${emoji.id}');
                _shareEmoji(context, emoji);
              },
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('加载图片失败: $error');
                      print('尝试加载的路径: $imagePath');
                      return const Icon(Icons.error);
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
