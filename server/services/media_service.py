"""
媒体服务 - 文件上传保存、URL 生成
"""
import os
import uuid
import aiofiles
from typing import Optional
from fastapi import UploadFile

from config import settings


# 允许的文件类型
ALLOWED_IMAGE_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/gif": ".gif",
    "image/webp": ".webp",
    "image/bmp": ".bmp",
}

ALLOWED_VIDEO_TYPES = {
    "video/mp4": ".mp4",
    "video/webm": ".webm",
    "video/quicktime": ".mov",
}

MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB


def ensure_media_dir():
    """确保 media 目录存在"""
    os.makedirs(settings.MEDIA_DIR, exist_ok=True)
    # 按日期分子目录
    from datetime import datetime
    date_str = datetime.now().strftime("%Y%m%d")
    sub_dir = os.path.join(settings.MEDIA_DIR, date_str)
    os.makedirs(sub_dir, exist_ok=True)
    return sub_dir


def get_file_extension(content_type: str, filename: str) -> str:
    """根据 content_type 或文件名获取扩展名"""
    # 优先从 content_type 判断
    if content_type in ALLOWED_IMAGE_TYPES:
        return ALLOWED_IMAGE_TYPES[content_type]
    if content_type in ALLOWED_VIDEO_TYPES:
        return ALLOWED_VIDEO_TYPES[content_type]

    # 从文件名提取
    _, ext = os.path.splitext(filename)
    if ext:
        return ext.lower()

    return ".bin"


def is_allowed_file(content_type: str, filename: str) -> bool:
    """检查文件类型是否允许"""
    if content_type in ALLOWED_IMAGE_TYPES:
        return True
    if content_type in ALLOWED_VIDEO_TYPES:
        return True

    # 检查扩展名
    _, ext = os.path.splitext(filename)
    allowed_exts = set(ALLOWED_IMAGE_TYPES.values()) | set(ALLOWED_VIDEO_TYPES.values())
    return ext.lower() in allowed_exts


async def save_upload_file(upload_file: UploadFile) -> Optional[str]:
    """
    保存上传的文件到 media 目录
    返回相对 URL 路径（如 /media/20240101/xxx.jpg）
    失败返回 None
    """
    ensure_media_dir()

    # 检查文件类型
    content_type = upload_file.content_type or ""
    filename = upload_file.filename or "upload"

    if not is_allowed_file(content_type, filename):
        return None

    # 生成唯一文件名
    ext = get_file_extension(content_type, filename)
    unique_name = f"{uuid.uuid4().hex}{ext}"

    # 按日期分子目录
    from datetime import datetime
    date_str = datetime.now().strftime("%Y%m%d")
    sub_dir = os.path.join(settings.MEDIA_DIR, date_str)
    os.makedirs(sub_dir, exist_ok=True)

    file_path = os.path.join(sub_dir, unique_name)

    # 异步写入文件
    try:
        async with aiofiles.open(file_path, "wb") as f:
            total_size = 0
            while True:
                chunk = await upload_file.read(1024 * 1024)  # 1MB chunks
                if not chunk:
                    break
                total_size += len(chunk)
                if total_size > MAX_FILE_SIZE:
                    await upload_file.close()
                    os.remove(file_path)
                    return None
                await f.write(chunk)

        await upload_file.close()

        # 返回相对 URL 路径
        return f"/media/{date_str}/{unique_name}"

    except Exception:
        await upload_file.close()
        if os.path.exists(file_path):
            os.remove(file_path)
        return None


def get_media_url(path: str, base_url: str = "") -> str:
    """
    获取媒体文件的完整 URL
    path: 相对路径（如 /media/20240101/xxx.jpg）
    base_url: 可选的基础 URL（如 http://localhost:24512）
    """
    if not path:
        return ""

    # 如果已经是完整 URL，直接返回
    if path.startswith("http://") or path.startswith("https://"):
        return path

    # 确保以 / 开头
    if not path.startswith("/"):
        path = "/" + path

    if base_url:
        return f"{base_url.rstrip('/')}{path}"

    return path


def get_media_path(url_path: str) -> Optional[str]:
    """
    将 URL 路径转换为本地文件系统路径
    """
    if not url_path:
        return None

    # 去掉 /media/ 前缀
    if url_path.startswith("/media/"):
        relative = url_path[len("/media/"):]
        return os.path.join(settings.MEDIA_DIR, relative)

    return None
