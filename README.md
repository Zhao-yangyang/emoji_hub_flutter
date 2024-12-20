# EmojiHub - 表情包管理应用

EmojiHub 是一款跨平台的表情包管理工具，帮助用户更好地整理和使用表情包。通过悬浮工具条和独立应用的结合，提供便捷的表情包管理和快速调用体验。

## 项目概述

### 产品目标
- 解决现有应用表情管理分散的问题
- 提供一站式表情包管理与跨平台共享服务
- 实现便捷的表情包快速调用功能

### 技术栈
- 框架：Flutter
- 数据库：SQLite
- 状态管理：Provider/Riverpod
- 存储：本地存储 + 云存储(待定)

## 功能规划

### 第一阶段：核心功能 (进行中)
- [ ] 表情包导入
  - [ ] 从相册选择图片
  - [ ] 批量导入支持
  - [ ] 导入进度显示
  
- [ ] 分类管理
  - [ ] 创建/编辑/删除分类
  - [ ] 分类排序
  - [ ] 表情分类标记

- [ ] 基础数据管理
  - [ ] SQLite 数据库设计与实现
  - [ ] 表情数据 CRUD 操作
  - [ ] 分类数据 CRUD 操作

### 第二阶段：表情管理
- [ ] 表情编辑
  - [ ] 重命名表情
  - [ ] 修改分类
  - [ ] 调整排序
  - [ ] 表情预览

- [ ] 删除功能
  - [ ] 单个删除
  - [ ] 批量删除
  - [ ] 回收站功能

### 第三阶段：悬浮工具条
- [ ] 基础实现
  - [ ] 悬浮窗权限管理
  - [ ] 创建与销毁
  - [ ] 拖拽定位

- [ ] 快捷功能
  - [ ] 表情网格展示
  - [ ] 分类快速切换
  - [ ] 表情预览
  - [ ] 复制到剪贴板
  - [ ] 分享到其他应用

### 第四阶段：高级功能
- [ ] 搜索功能
  - [ ] 按名称搜索
  - [ ] 按分类筛选
  
- [ ] 分享功能
  - [ ] 单个表情分享
  - [ ] 分类批量分享
  
- [ ] 数据管理
  - [ ] 云端备份与恢复
  - [ ] 多设备同步
  - [ ] 设置页面

## 项目结构
lib/
├── core/ # 核心功能
│ ├── constants/ # 常量定义
│ ├── utils/ # 工具类
│ └── services/ # 基础服务
├── data/ # 数据层
│ ├── models/ # 数据模型
│ ├── repositories/ # 数据仓库
│ └── providers/ # 数据提供者
├── features/ # 功能模块
│ ├── emoji_manager/ # 表情管理
│ ├── floating_panel/ # 悬浮面板
│ └── settings/ # 设置
├── ui/ # UI 组件
│ ├── widgets/ # 通用组件
│ ├── screens/ # 页面
│ └── themes/ # 主题
└── main.dart # 入口文件

## 开发计划

### 当前开发重点
1. 完成基础数据库设计与实��
2. 实现表情包导入和分类管理基础功能
3. 搭建基础 UI 框架

### 后期规划
1. 优化用户体验
2. 实现云端同步功能
3. 开发跨平台分享功能
4. 添加高级特性

## 环境要求
- Flutter SDK: ^3.6.0
- Dart SDK: ^3.6.0
- Android SDK: 最低支持 API 21
- iOS: 最低支持 iOS 11.0

## 如何运行

### 方式一：命令行运行
1. 确保已安装 Flutter 环境
```bash
flutter doctor
```

2. 获取依赖
```bash
flutter pub get
```

3. 运行项目
```bash
flutter run
```

### 方式二：VS Code 运行（推荐）
1. 安装必要插件：
   - Flutter 插件
   - Dart 插件

2. 运行项目：
   - 在底部状态栏选择目标设备
   - 点击右上角运行按钮或按 F5 键

3. 常用快捷键：
   - `r`: 热重载
   - `R`: 热重启
   - `Cmd/Ctrl + .`: 快速修复
   - `F5`: 开始调试
   - `Shift + F5`: 停止调试

4. 实用功能：
   - Flutter Outline：查看 Widget 树
   - Dart DevTools：调试工具
   - 底部状态栏：设备选择、热重载按钮

## 贡献指南
1. Fork 项目
2. 创建特性分支
3. 提交改动
4. 发起 Pull Request

## 许可证
MIT License

## UI设计规范

### 设计理念
1. **极简主义风格**
   - 采用简洁的界面布局
   - 重点突出内容
   - 使用大量留白增加视觉呼吸感

2. **现代化配色**
   - 主色调：深色模式为主
   - 强调色：使用鲜艳的荧光色点缀
   - 渐变效果：适当使用玻璃拟态效果

### 颜色规范
```dart
// 主要背景色
static const Color background = Color(0xFF1E1E1E);

// 次要背景色
static const Color surface = Color(0xFF2D2D2D);

// 强调色
static const Color accent = Color(0xFF00E5FF);

// 文字颜色
static const Color textPrimary = Colors.white;
static const Color textSecondary = Color(0xFFB3B3B3);
```

### 页面结构
1. **主页(HomeScreen)**
   - 顶部: 渐变AppBar
   - 中部: 横向滚动分类列表
   - 底部: 表情包网格展示
   - 右下角: 玻璃拟态浮动按钮

2. **分类管理页**
   - 支持拖拽排序
   - 编辑/删除功能
   - 新建分类功能

3. **表情详情页**
   - 大图预览
   - 基础信息编辑
   - 快速分享功能

### 交互设计
1. **动效设计**
   - 页面切换动画
   - 微交互反馈
   - 骨架屏加载

2. **手势操作**
   - 左右滑动切换分类
   - 长按进入编辑模式
   - 双击快速预览

## 开发计划更新

### 第一阶段：基础框架搭建
1. **项目配置**
   - [x] 创建基础项目结构
   - [ ] 配置必要依赖
   - [ ] 设置开发环境

2. **UI框架实现**
   - [ ] 实现主题配置
   - [ ] 创建基础组件
   - [ ] 搭建页面框架

3. **数据层开发**
   - [ ] 设计数据模型
   - [ ] 实现数据存储
   - [ ] 完成基础CRUD

### 所需依赖
```yaml
dependencies:
  # UI相关
  glassmorphism: ^3.0.0
  flutter_staggered_grid_view: ^0.7.0
  
  # 状态管理
  flutter_riverpod: ^2.4.9
  
  # 数据存储
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  
  # 图片处理
  image_picker: ^1.0.7
  cached_network_image: ^3.3.0
  
  # 动画效果
  animations: ^2.0.8
  
  # 工具类
  permission_handler: ^11.1.0
```

### 下一步开发重点
1. 完成主页面框架搭建
2. 实现基础UI组件
3. 配置主题系统