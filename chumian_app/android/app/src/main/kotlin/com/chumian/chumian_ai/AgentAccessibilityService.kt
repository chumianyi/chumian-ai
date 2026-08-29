package com.chumian.chumian_ai

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.os.Build
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class AgentAccessibilityService : AccessibilityService() {

    companion object {
        var instance: AgentAccessibilityService? = null
            private set
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d("AgentAccessibility", "Service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }

    fun getNodeTree(): String {
        val root = rootInActiveWindow ?: return "无法获取窗口"
        val sb = StringBuilder()
        dumpNode(root, 0, sb)
        return sb.toString()
    }

    private fun dumpNode(node: AccessibilityNodeInfo, depth: Int, sb: StringBuilder) {
        if (depth > 8) return
        val indent = "  ".repeat(depth)
        val text = node.text?.toString() ?: ""
        val desc = node.contentDescription?.toString() ?: ""
        val cls = node.className?.toString()?.split(".")?.last() ?: ""
        val clickable = node.isClickable
        val bounds = node.getBoundsInScreen(android.graphics.Rect())
        sb.append("$indent[$cls] text=\"$text\" desc=\"$desc\" clickable=$clickable bounds=[${bounds.left},${bounds.top},${bounds.right},${bounds.bottom}]\n")
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            dumpNode(child, depth + 1, sb)
        }
    }

    fun clickByText(targetText: String): Boolean {
        val root = rootInActiveWindow ?: return false
        val node = findNodeByText(root, targetText)
        if (node != null) {
            val result = node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            if (!result) {
                // 尝试点击坐标
                val bounds = android.graphics.Rect()
                node.getBoundsInScreen(bounds)
                return clickAt(bounds.centerX(), bounds.centerY())
            }
            return true
        }
        return false
    }

    private fun findNodeByText(node: AccessibilityNodeInfo, target: String): AccessibilityNodeInfo? {
        val text = node.text?.toString() ?: ""
        val desc = node.contentDescription?.toString() ?: ""
        if (text.contains(target, ignoreCase = true) || desc.contains(target, ignoreCase = true)) {
            if (node.isClickable) return node
            var parent = node.parent
            while (parent != null) {
                if (parent.isClickable) return parent
                parent = parent.parent
            }
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val found = findNodeByText(child, target)
            if (found != null) return found
        }
        return null
    }

    fun inputText(text: String): Boolean {
        val root = rootInActiveWindow ?: return false
        val editText = findEditText(root)
        if (editText != null) {
            val args = android.os.Bundle()
            args.putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
            return editText.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
        }
        return false
    }

    private fun findEditText(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (node.className?.toString()?.contains("EditText", ignoreCase = true) == true) {
            return node
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val found = findEditText(child)
            if (found != null) return found
        }
        return null
    }

    fun clickAt(x: Int, y: Int): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false
        val path = Path()
        path.moveTo(x.toFloat(), y.toFloat())
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 100))
            .build()
        return dispatchGesture(gesture, null, null)
    }

    fun performGlobalAction(action: String): Boolean {
        val actionId = when (action) {
            "back" -> GLOBAL_ACTION_BACK
            "home" -> GLOBAL_ACTION_HOME
            "recent" -> GLOBAL_ACTION_RECENTS
            "notifications" -> GLOBAL_ACTION_NOTIFICATIONS
            "quick_settings" -> GLOBAL_ACTION_QUICK_SETTINGS
            else -> GLOBAL_ACTION_BACK
        }
        return performGlobalAction(actionId)
    }
}
