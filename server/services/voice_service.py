"""
语音服务 - VoiceService
功能：
- TTS（文本转语音）上游 API 调用
- STT（语音转文字）上游 API 调用
- 音色管理
- 任务历史
未配置上游 Key 时返回错误，绝不生成模拟音频或假转写文本
"""
import os
import uuid
from typing import Dict, Any, Optional, List
from datetime import datetime, timezone

from config import settings
from database import get_db_conn, fetch_one, fetch_all, execute


# ===== 音色配置 =====
VOICES = {
    "default": {
        "name": "默认女声",
        "gender": "female",
        "language": "zh-CN",
        "sample_rate": 22050,
        "base_freq": 220,
        "description": "清晰自然的中文女声",
    },
    "male_calm": {
        "name": "沉稳男声",
        "gender": "male",
        "language": "zh-CN",
        "sample_rate": 22050,
        "base_freq": 130,
        "description": "低沉稳重的中文男声",
    },
    "female_bright": {
        "name": "明亮女声",
        "gender": "female",
        "language": "zh-CN",
        "sample_rate": 22050,
        "base_freq": 280,
        "description": "明亮活泼的中文女声",
    },
    "child": {
        "name": "童声",
        "gender": "child",
        "language": "zh-CN",
        "sample_rate": 22050,
        "base_freq": 350,
        "description": "清脆可爱的童声",
    },
    "english_female": {
        "name": "English Female",
        "gender": "female",
        "language": "en-US",
        "sample_rate": 22050,
        "base_freq": 200,
        "description": "Clear English female voice",
    },
    "english_male": {
        "name": "English Male",
        "gender": "male",
        "language": "en-US",
        "sample_rate": 22050,
        "base_freq": 110,
        "description": "Deep English male voice",
    },
}


class VoiceService:
    """语音服务"""

    def __init__(self):
        self.voice_dir = os.path.join(settings.MEDIA_DIR, "voice")
        os.makedirs(self.voice_dir, exist_ok=True)

    async def text_to_speech(
        self,
        text: str,
        voice_id: str = "default",
        speed: float = 1.0,
        pitch: float = 1.0,
    ) -> Dict[str, Any]:
        """
        文本转语音
        未配置 ZHIPU_API_KEY 时抛出异常
        """
        if not text or not text.strip():
            raise ValueError("文本不能为空")

        if not settings.ZHIPU_API_KEY:
            raise RuntimeError("未配置模型密钥，请在服务端配置 ZHIPU_API_KEY 环境变量")

        voice = VOICES.get(voice_id, VOICES["default"])

        # 参数校验
        speed = max(0.5, min(2.0, speed))
        pitch = max(0.5, min(2.0, pitch))

        # 未接入真实 TTS 上游 API，返回明确错误
        raise RuntimeError("语音合成上游服务未配置")

    async def speech_to_text(
        self,
        audio_url: str,
        language: str = "zh-CN",
    ) -> Dict[str, Any]:
        """
        语音转文字
        未配置 ZHIPU_API_KEY 时抛出异常
        """
        if not audio_url:
            raise ValueError("音频地址不能为空")

        if not settings.ZHIPU_API_KEY:
            raise RuntimeError("未配置模型密钥，请在服务端配置 ZHIPU_API_KEY 环境变量")

        # 未接入真实 STT 上游 API，返回明确错误
        raise RuntimeError("语音识别上游服务未配置")

    def get_voices(self) -> List[Dict[str, Any]]:
        """获取所有可用音色"""
        return [
            {
                "id": vid,
                "name": v["name"],
                "gender": v["gender"],
                "language": v["language"],
                "description": v["description"],
                "sample_rate": v["sample_rate"],
            }
            for vid, v in VOICES.items()
        ]

    def get_voice(self, voice_id: str) -> Optional[Dict[str, Any]]:
        """获取指定音色详情"""
        v = VOICES.get(voice_id)
        if not v:
            return None
        return {"id": voice_id, **v}

    async def get_history(
        self,
        user_id: str,
        page: int = 1,
        page_size: int = 20,
        task_type: Optional[str] = None,
    ) -> Dict[str, Any]:
        """获取语音任务历史"""
        offset = (page - 1) * page_size
        conditions = ["1=1"]
        params: list = []

        if task_type:
            conditions.append("task_type = ?")
            params.append(task_type)

        where = " AND ".join(conditions)

        async with get_db_conn() as conn:
            rows = await fetch_all(
                conn,
                f"""SELECT id, task_type, text, voice_id, speed, pitch,
                           audio_url, duration, file_size, status, created_at
                    FROM voice_tasks
                    WHERE {where}
                    ORDER BY created_at DESC LIMIT ? OFFSET ?""",
                tuple(params + [page_size, offset]),
            )
            total_row = await fetch_one(
                conn,
                f"SELECT COUNT(*) as cnt FROM voice_tasks WHERE {where}",
                tuple(params),
            )

        return {
            "items": rows,
            "total": total_row["cnt"] if total_row else 0,
            "page": page,
            "page_size": page_size,
        }


# 全局单例
voice_service = VoiceService()
