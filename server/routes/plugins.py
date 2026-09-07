"""
插件路由
支持：
- GET  /api/plugins — 插件列表
- GET  /api/plugins/{id} — 插件详情
- POST /api/plugins/{id}/execute — 执行插件
- POST /api/plugins/install — 安装插件
- DELETE /api/plugins/{id}/uninstall — 卸载插件
- GET  /api/plugins/installed — 已安装插件
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any

from auth import get_current_user
from services.plugin_service import plugin_service

router = APIRouter()


# ===== 请求模型 =====
class ExecutePluginRequest(BaseModel):
    params: Dict[str, Any] = Field(default_factory=dict, description="插件参数")


class InstallPluginRequest(BaseModel):
    plugin_id: str = Field(..., description="插件ID")
    config: Optional[Dict[str, Any]] = Field(None, description="插件配置")


# ===== 插件列表 =====
@router.get("/api/plugins")
async def list_plugins(
    category: Optional[str] = Query(None, description="按分类筛选"),
    current_user: dict = Depends(get_current_user),
):
    """获取所有可用插件列表"""
    if category:
        plugins = plugin_service.get_plugins_by_category(category)
    else:
        plugins = plugin_service.get_all_plugins()

    return {
        "code": 0,
        "message": "success",
        "data": {
            "plugins": plugins,
            "total": len(plugins),
        },
    }


# ===== 插件详情 =====
@router.get("/api/plugins/{plugin_id}")
async def get_plugin_detail(
    plugin_id: str,
    current_user: dict = Depends(get_current_user),
):
    """获取插件详情"""
    plugin = plugin_service.get_plugin(plugin_id)
    if not plugin:
        raise HTTPException(status_code=404, detail=f"插件不存在: {plugin_id}")

    return {"code": 0, "message": "success", "data": plugin}


# ===== 执行插件 =====
@router.post("/api/plugins/{plugin_id}/execute")
async def execute_plugin(
    plugin_id: str,
    body: ExecutePluginRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    执行指定插件
    传入插件参数，返回执行结果
    """
    plugin = plugin_service.get_plugin(plugin_id)
    if not plugin:
        raise HTTPException(status_code=404, detail=f"插件不存在: {plugin_id}")

    try:
        result = await plugin_service.execute_plugin(
            plugin_id=plugin_id,
            params=body.params,
            user_id=current_user["id"],
        )
        return {"code": 0, "message": "执行成功", "data": result}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"插件执行失败: {e}")


# ===== 安装插件 =====
@router.post("/api/plugins/install")
async def install_plugin(
    body: InstallPluginRequest,
    current_user: dict = Depends(get_current_user),
):
    """安装插件"""
    plugin = plugin_service.get_plugin(body.plugin_id)
    if not plugin:
        raise HTTPException(status_code=404, detail=f"插件不存在: {body.plugin_id}")

    try:
        result = await plugin_service.install_plugin(
            plugin_id=body.plugin_id,
            user_id=current_user["id"],
            plugin_config=body.config,
        )
        return {"code": 0, "message": "插件安装成功", "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"安装失败: {e}")


# ===== 卸载插件 =====
@router.delete("/api/plugins/{plugin_id}/uninstall")
async def uninstall_plugin(
    plugin_id: str,
    current_user: dict = Depends(get_current_user),
):
    """卸载插件"""
    success = await plugin_service.uninstall_plugin(plugin_id, current_user["id"])
    if not success:
        raise HTTPException(status_code=404, detail="插件未安装或不存在")

    return {"code": 0, "message": "插件已卸载"}


# ===== 已安装插件 =====
@router.get("/api/plugins/installed/list")
async def get_installed_plugins(
    current_user: dict = Depends(get_current_user),
):
    """获取当前用户已安装的插件列表"""
    plugins = await plugin_service.get_installed_plugins(current_user["id"])
    return {
        "code": 0,
        "message": "success",
        "data": {
            "plugins": plugins,
            "total": len(plugins),
        },
    }


# ===== 插件分类列表 =====
@router.get("/api/plugins/categories/list")
async def get_categories(
    current_user: dict = Depends(get_current_user),
):
    """获取所有插件分类"""
    all_plugins = plugin_service.get_all_plugins()
    categories = set()
    for p in all_plugins:
        for cat in p.get("categories", []):
            categories.add(cat)

    return {
        "code": 0,
        "message": "success",
        "data": {
            "categories": sorted(list(categories)),
            "total": len(categories),
        },
    }
