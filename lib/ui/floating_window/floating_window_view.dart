import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emoji_hub_flutter/core/services/floating_window_service.dart';

class FloatingWindowView extends ConsumerStatefulWidget {
  const FloatingWindowView({Key? key}) : super(key: key);

  @override
  ConsumerState<FloatingWindowView> createState() => _FloatingWindowViewState();
}

class _FloatingWindowViewState extends ConsumerState<FloatingWindowView> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _emojis = [
    '😊',
    '😂',
    '🤣',
    '😍',
    '😒',
    '😘',
    '🥰',
    '😎',
    '🤔',
    '😅',
    '😱',
    '😭',
    '🥺',
    '😤',
    '😡',
    '🤮'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          children: [
            // 表情包网格
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _emojis.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      // TODO: 实现表情点击功能
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _emojis[index],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 底部搜索栏
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '搜索表情',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        // TODO: 实现搜索功能
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
