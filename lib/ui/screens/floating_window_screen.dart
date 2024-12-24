import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'dart:io';
import '../../data/repositories/emoji_repository.dart';
import '../../data/models/emoji.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FloatingWindowScreen extends StatefulWidget {
  const FloatingWindowScreen({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Material(
        color: Colors.transparent,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_emojis.isEmpty) {
      return const Material(
        color: Colors.transparent,
        child: Center(child: Text('没有表情')),
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
            return GestureDetector(
              onTap: () {
                // TODO: 实现复制功能
              },
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.file(
                    File(_getFullPath(emoji.path)),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('加载图片失败: $error');
                      print('尝试加载的路径: ${_getFullPath(emoji.path)}');
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
