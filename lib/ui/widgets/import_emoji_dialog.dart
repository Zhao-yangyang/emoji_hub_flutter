import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/emoji_repository.dart'
    hide emojiRepositoryProvider;
import '../../providers/app_provider.dart';
import '../../core/utils/error_handler.dart';

class ImportEmojiDialog extends ConsumerStatefulWidget {
  const ImportEmojiDialog({super.key});

  @override
  ConsumerState<ImportEmojiDialog> createState() => _ImportEmojiDialogState();
}

class _ImportEmojiDialogState extends ConsumerState<ImportEmojiDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<XFile> _selectedImages = [];
  double _importProgress = 0.0;

  Future<void> _pickImages() async {
    try {
      print('开始选择图片...');
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      print('选择了 ${images.length} 张图片');

      if (images.isNotEmpty) {
        // 获取应用文档目录
        final appDir = await getApplicationDocumentsDirectory();
        print('应用文档目录: ${appDir.path}');

        final tempDir = Directory('${appDir.path}/temp');
        print('临时目录: ${tempDir.path}');

        if (!await tempDir.exists()) {
          await tempDir.create(recursive: true);
          print('创建临时目录');
        }

        // 立即复制选中的图片到临时目录
        final copiedImages = <XFile>[];
        for (var image in images) {
          print('处理图片: ${image.path}');
          print('图片名称: ${image.name}');

          try {
            // 读取图片数据
            final bytes = await image.readAsBytes();
            print('读取图片数据成功，大小: ${bytes.length} bytes');

            final tempFile = File('${tempDir.path}/${image.name}');
            print('准备写入临时文件: ${tempFile.path}');

            // 写入数据到新文件
            await tempFile.writeAsBytes(bytes);
            print('写入临时文件成功');

            copiedImages.add(XFile(tempFile.path));
            print('添加到待处理列表');
          } catch (e) {
            print('处理单张图片失败: $e');
          }
        }

        print('开始更新界面，共 ${copiedImages.length} 张图片');
        setState(() {
          _selectedImages.addAll(copiedImages);
        });
        print('界面更新完成');
      }
    } catch (e) {
      print('选择图片过程出错: $e');
      if (mounted) {
        ErrorHandler.showError(context, '选择图片失败: $e');
      }
    }
  }

  Future<void> _importEmojis() async {
    print('开始导入表情...');
    if (_selectedImages.isEmpty) {
      print('没有选择图片');
      ErrorHandler.showError(context, '请先选择图片');
      return;
    }

    final categoryId = ref.read(selectedCategoryIdProvider);
    print('当前分类ID: $categoryId');

    if (categoryId == null) {
      print('未选择分类');
      ErrorHandler.showError(context, '请先选择一个分类');
      return;
    }

    try {
      final repository = ref.read(emojiRepositoryProvider);
      int imported = 0;

      for (var image in _selectedImages) {
        print('导入图片: ${image.path}');
        final emoji = await repository.addEmoji(
          name: image.name.split('.').first,
          path: image.path,
          categoryId: categoryId,
        );

        if (emoji != null) {
          imported++;
          print('导入成功: ${emoji.path}');
          setState(() {
            _importProgress = imported / _selectedImages.length;
          });
        } else {
          print('导入失败');
        }
      }

      print('导入完成，成功: $imported/${_selectedImages.length}');
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功导入 $imported 个表情'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('导入过程出错: $e');
      ErrorHandler.showError(context, '导入失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              const Text(
                '批量导入表情',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 已选图片预览网格
              if (_selectedImages.isNotEmpty)
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImages[index].path),
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),

              // 导入进度条
              if (_importProgress > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: LinearProgressIndicator(value: _importProgress),
                ),

              // 按钮区域
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 选择图片按钮
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate, size: 20),
                      label: Text(
                        '选择图片 (${_selectedImages.length})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 取消和导入按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('取消'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed:
                              _selectedImages.isEmpty ? null : _importEmojis,
                          child: const Text('导入'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
