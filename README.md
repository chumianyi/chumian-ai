# 初眠AI (ChumianAI) v3.0

智能AI助手，粉色 Miuix 风格，支持流式对话、AI工具集、图片/视频生成、社区广场、自定义智能体、游戏娱乐。

## 技术栈

- **客户端**: Flutter 3.5+ (自研 Miuix 组件库)
- **服务端**: Python FastAPI + SQLite + SSE 流式
- **AI模型**: 智谱AI (GLM-4 系列, CogView, CogVideoX)
- **状态管理**: Provider
- **网络**: Dio + SSE
- **图标**: flutter_svg (全 SVG)

## 项目结构

```
chumian_work/
├── server/                    # FastAPI 服务端 (49个 .py 文件)
│   ├── main.py               # 入口，117+ API 端点
│   ├── config.py             # 配置
│   ├── database.py           # aiosqlite 异步数据库
│   ├── models.py             # Pydantic 模型
│   ├── auth.py               # JWT 认证
│   ├── migrations.py         # 数据库迁移
│   ├── routes/               # 路由 (19个模块)
│   │   ├── auth.py, chat.py, user.py, posts.py
│   │   ├── agents.py, shop.py, activity.py, search.py
│   │   ├── notifications.py, legal.py, writing.py
│   │   ├── image_gen.py, analytics.py, admin.py
│   │   ├── feedback.py, push.py, friends.py
│   │   ├── achievements.py, wallet.py, voice.py
│   │   ├── music.py, export.py, plugins.py, ws.py
│   ├── services/             # 业务服务 (15个)
│   │   ├── llm_service.py, search_service.py
│   │   ├── media_service.py, writing_service.py
│   │   ├── image_gen_service.py, analytics_service.py
│   │   ├── push_service.py, achievement_service.py
│   │   ├── task_queue.py, rate_limiter.py
│   │   ├── content_moderation.py, voice_service.py
│   │   ├── music_service.py, export_service.py
│   │   ├── plugin_service.py, websocket_manager.py
│   ├── data/chumian.db      # SQLite 数据库
│   ├── media/                # 媒体文件
│   ├── requirements.txt
│   └── start.sh
├── chumian_app/              # Flutter 客户端 (316个 .dart 文件)
│   ├── lib/
│   │   ├── main.dart         # 入口，全局水晕，Provider
│   │   ├── theme/            # 粉色 Miuix 色板体系
│   │   │   └── miuix_colors.dart
│   │   ├── widgets/
│   │   │   ├── miuix/        # Miuix 基础组件 (30个)
│   │   │   ├── advanced/     # 高级组件 (32个)
│   │   │   ├── chat/         # 聊天专用组件 (10个)
│   │   │   └── common/       # 通用组件 (20个)
│   │   ├── pages/            # 页面 (100+ 个)
│   │   │   ├── chat_page.dart, home_page.dart
│   │   │   ├── login_page.dart, register_page.dart
│   │   │   ├── ai_tools/     # AI 工具 (28个)
│   │   │   ├── games/        # 游戏 (10个)
│   │   │   ├── entertainment/ # 娱乐 (6个)
│   │   │   ├── tools/        # 工具 (12个)
│   │   │   ├── settings/     # 设置 (11个)
│   │   │   ├── profile/      # 个人 (10个)
│   │   │   ├── community/    # 社区 (6个)
│   │   │   ├── shop/         # 商城 (3个)
│   │   │   ├── activity/     # 活动 (3个)
│   │   │   └── mascot/       # 吉祥物 (2个)
│   │   ├── providers/        # 状态管理 (8个)
│   │   ├── services/         # 服务 (24个)
│   │   ├── models/           # 数据模型 (26个)
│   │   ├── utils/            # 工具类 (20个)
│   │   └── animations/       # 动画 (11个)
│   ├── assets/
│   │   ├── icon/app_icon.png # 应用图标 (从角色头部截取)
│   │   ├── mascot/           # AI 角色形象
│   │   └── svg/              # SVG 图标 (地球/机器人)
│   └── android/              # Android 原生
├── .github/workflows/        # CI/CD
└── README.md
```

## 核心特性

### 粉色 Miuix 设计
- 自研 Miuix 组件库 (92+ 组件)，对标小米 HyperOS
- 连续曲率圆角、毛玻璃、细腻高光、弹簧式按压回弹
- 全局粉色水晕涟漪，点击任意位置都有反馈
- 整体粉色系主题，暗色模式也为粉调

### 动画拉满
- 底部导航：点击项先缩到 0.3 → 弹性放大 → 进入页面
- 列表错落入场、页面缩放淡入转场
- 按钮按压缩放回弹、卡片悬浮、加载骨架屏
- 打字机效果、数字滚动、语音波形、AI 输入指示器

### 聊天体验
- SSE 流式对话，思考过程可折叠
- 扁平化单层输入框 (彻底消除双框)
- 模型切换移至右上角
- 输入框上方两枚 SVG 胶囊：联网搜索 + 更换模型
- 联网搜索由 AI 自主决定，可查看来源条目
- 复制消息为纯文本 (自动剥离 Markdown 符号)
- 语音输入、图片/视频生成

### AI 工具集 (28+)
- 写作、翻译、代码、绘画、总结、写诗
- 作文、续写故事、邮件、社交媒体文案
- 标语、起名、菜谱、健身、旅行规划
- 简历、求职信、面试模拟、数学解题
- 语法检查、改写润色、标题生成、PPT大纲
- 思维导图、OCR、PDF总结、语音合成、音乐生成

### 游戏娱乐 (16+)
- 井字棋、贪吃蛇、记忆翻牌、打地鼠、2048
- 石头剪刀布、知识问答、颜色匹配、数字华容道、骰子
- 笑话大全、运势测算、星座运势、姓名测试
- 帮你决定、抛硬币

### 服务端
- FastAPI 异步，117+ API 端点
- SSE 流式聊天，9 种模型
- JWT 认证，密码哈希
- 联网搜索、AI 写作/绘画
- 积分商城、签到、活动竞猜
- 成就系统、钱包、好友社交
- 管理员后台、内容审核、数据统计
- WebSocket 实时通信
- 无 API Key 时模拟回复可运行

## 代码统计

- **Dart 源码**: 316 文件，约 3.95 MB
- **Python 源码**: 49 文件，约 0.36 MB
- **业务源码总量**: 约 4.11 MB (不含资源)
- **仅系统字体**: 无任何第三方字体打包
- **全 SVG 图标**: 无位图图标依赖

## 服务端部署

```bash
cd server
pip3 install -r requirements.txt
./start.sh
# 或
python3 main.py
# 默认端口 24512
```

## 客户端构建

```bash
cd chumian_app
flutter pub get
flutter build apk --release --target-platform android-arm64
```

## 服务器信息

- 地址: 103.236.99.177
- API端口: 24512
