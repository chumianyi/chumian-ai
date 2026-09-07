"""
语音路由
支持：
- POST /api/voice/tts — 文本转语音
- POST /api/voice/stt — 语音转文字
- GET  /api/voice/voices — 可用音色列表
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from typing import Optional

from auth import get_current_user
from services.voice_service import voice_service

router = APIRouter()


# ===== 请求模型 =====
class TTSRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=5000, description="要转换的文本")
    voice_id: str = Field("default", description="音色ID")
    speed: float = Field(1.0, ge=0.5, le=2.0, description="语速 (0.5-2.0)")
    pitch: float = Field(1.0, ge=0.5, le=2.0, description="音调 (0.5-2.0)")


class STTRequest(BaseModel):
    audio_url: str = Field(..., description="音频文件URL或路径")
    language: str = Field("zh-CN", description="语言代码")


# ===== TTS 文本转语音 =====
@router.post("/api/voice/tts")
async def text_to_speech(
    body: TTSRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    文本转语音
    将文本转换为 WAV 格式音频，支持多种音色、语速和音调
    """
    try:
        result = await voice_service.text_to_speech(
            text=body.text,
            voice_id=body.voice_id,
            speed=body.speed,
            pitch=body.pitch,
        )
        return {"code": 0, "message": "语音生成成功", "data": result}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"语音生成失败: {e}")


# ===== STT 语音转文字 =====
@router.post("/api/voice/stt")
async def speech_to_text(
    body: STTRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    语音转文字
    从音频文件中提取文本内容
    """
    try:
        result = await voice_service.speech_to_text(
            audio_url=body.audio_url,
            language=body.language,
        )
        return {"code": 0, "message": "语音识别成功", "data": result}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"语音识别失败: {e}")


# ===== 可用音色列表 =====
@router.get("/api/voice/voices")
async def get_voices(
    language: Optional[str] = Query(None, description="按语言筛选"),
    current_user: dict = Depends(get_current_user),
):
    """
    获取所有可用音色列表
    支持按语言筛选
    """
    voices = voice_service.get_voices()

    if language:
        voices = [v for v in voices if v["language"].startswith(language)]

    return {
        "code": 0,
        "message": "success",
        "data": {
            "voices": voices,
            "total": len(voices),
        },
    }


# ===== 语音任务历史 =====
@router.get("/api/voice/history")
async def get_voice_history(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    task_type: Optional[str] = Query(None, description="任务类型: tts/stt"),
    current_user: dict = Depends(get_current_user),
):
    """获取当前用户的语音任务历史"""
    result = await voice_service.get_history(
        user_id=current_user["id"],
        page=page,
        page_size=page_size,
        task_type=task_type,
    )
    return {"code": 0, "message": "success", "data": result}
