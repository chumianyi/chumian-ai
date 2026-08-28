# 初眠AI (ChumianAI)

智能AI助手，支持流式对话、图片生成、视频生成、社区广场、自定义智能体。

## 技术栈

- **客户端**: Flutter (Material 3)
- **服务端**: Python FastAPI + SQLite
- **AI模型**: 智谱AI (GLM-4, CogView, CogVideoX)
- **部署**: systemd 服务，端口 24513

## 项目结构

```
chumian_ai/
├── server/              # FastAPI 服务端
│   ├── main.py         # 主服务文件
│   ├── requirements.txt
│   ├── data/           # SQLite 数据库
│   └── media/          # 生成的图片/视频
├── chumian_app/        # Flutter 客户端
│   ├── lib/
│   │   ├── main.dart
│   │   ├── theme.dart
│   │   ├── pages/      # 登录、对话、探索、创意、个人中心
│   │   ├── providers/  # 状态管理
│   │   └── services/   # API 服务
│   └── android/
└── README.md
```

## 功能特性

- 流式AI对话（支持思考过程展示）
- 多模型切换（GLM-4-Flash, GLM-4.7-Flash, GLM-Z1-Flash）
- 图片生成（CogView-3）
- 视频生成（CogVideoX）
- 对话历史管理
- 社区广场（帖子、评论、点赞）
- 自定义AI智能体
- 邮箱注册登录
- 积分系统

## 服务端部署

```bash
cd server
pip install -r requirements.txt
python3 main.py
# 默认端口 24513
```

## 客户端构建

```bash
cd chumian_app
flutter pub get
flutter build apk --release --target-platform android-arm64
```

## 服务器信息

- 地址: 103.236.99.177
- SSH: 29982
- API端口: 24513 (TCP)
- 服务管理: systemctl chumian-ai.service
