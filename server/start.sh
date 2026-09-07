#!/bin/bash
# 触面 AI 服务端启动脚本
cd "$(dirname "$0")"

# 设置环境变量
export CHUMIAN_DB_PATH="$(pwd)/data/chumian.db"
export CHUMIAN_MEDIA_DIR="$(pwd)/media"
export CHUMIAN_PORT="${CHUMIAN_PORT:-24512}"

# 可选：取消注释并设置你的 API Key
# export ZHIPU_API_KEY="your-zhipu-api-key"
# export SEARCH_API_KEY="your-search-api-key"
# export JWT_SECRET="your-jwt-secret"

echo "=========================================="
echo "  触面 AI 服务端启动中..."
echo "  数据库: $CHUMIAN_DB_PATH"
echo "  媒体目录: $CHUMIAN_MEDIA_DIR"
echo "  端口: $CHUMIAN_PORT"
echo "=========================================="

# 使用 uvicorn 启动
exec uvicorn main:app --host 0.0.0.0 --port "${CHUMIAN_PORT:-24512}"
