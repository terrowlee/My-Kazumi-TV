# My-Kazumi-TV 项目计划

> 目标：基于 znbsf/Kazumi 的 TV 适配分支，产出可在 Sony 85X90K（Google TV）上安装使用的 My-Kazumi-TV：修复弹幕获取、按 MyTVB 模式补全遥控器交互。
> 本文档是项目交接的唯一依据，不依赖任何会话历史。

## 基线选择

- 仓库：`https://github.com/znbsf/Kazumi`
- 分支：`codex/tv-phase1-hardening`（2026-09-12 更新，已变基整合上游 main/2.3.1 + TV 第一阶段焦点适配）
- 放弃 `codex/android-tv-phase1`（基于 2.3.0，已被 hardening 分支变基取代）
- 原版 Predidit/Kazumi 官方无 TV 适配计划（TV issue #2461/#2500 零回应，TV PR 被秒关）
- 备选 wyrmjin/kazumi-tv 已否决（基于 2.0.8、落后 239 commits、停滞）

## 构建环境（隔离安装）

所有工具位于 `.sdk/`，只通过环境变量指向，不改注册表/系统 PATH，可整体删除。
注意：uv 是 Python 专用工具，不适用于 Flutter/JDK/Android SDK；用目录隔离达到同等"可整体卸载"效果。

| 组件 | 位置 | 说明 |
|---|---|---|
| JDK 17 (Temurin) | `.sdk/jdk17/` | zip 解压版 |
| Android SDK | `.sdk/android-sdk/` | cmdline-tools + platform-tools + build-tools + platforms |
| Flutter 3.47.2 | `.sdk/flutter/` | pubspec.yaml 锁定该版本 |

环境变量（构建会话中设置）：
```
JAVA_HOME=D:\python\code\My-Kazumi-TV\.sdk\jdk17
ANDROID_HOME=D:\python\code\My-Kazumi-TV\.sdk\android-sdk
PATH 追加 .sdk\flutter\bin 与 .sdk\android-sdk\platform-tools
```

## 阶段与验收

- **A 环境搭建**：flutter doctor 无致命错误
- **B 基线**：克隆分支 → pub get → debug arm64 APK 编译通过
- **C TV 化**：AndroidManifest 加 leanback feature（required=false）+ LEANBACK_LAUNCHER category；应用改名 My-Kazumi-TV（arb 本地化文件）；release arm64 APK
- **D 弹幕修复**：链路在 `lib/request/apis/danmaku_api.dart`、`lib/request/config/api_endpoints.dart`（弹弹play 公开 v2 API，平台无关）；排查 TV 端失败原因，补超时/重试/备用域名/失败提示
- **E 遥控器交互（蓝本 MyTVB：github.com/qianxuntudou-ops/MyTVB）**：
  1. 统一按键路由链：设置面板 → seek 会话 → 进度条 → 控制栏 → 兜底
  2. OK 键两态语义：控制栏隐藏=播放/暂停；显示=激活焦点按钮
  3. 上下键 IPTV 式切换视频 + OSD 提示
  4. SeekSession：松开生效、长按连发、返回键取消
  5. 焦点恢复仲裁（从播放器返回列表精确回到原卡片）
  6. 菜单打开自动定位当前选中项；ROM 键码 280–283 兼容
  7. 复用分支已有 `lib/bean/widget/tv_focusable_surface.dart` 焦点基建
- **验证**：adb（Wi-Fi/USB）安装到 Sony X90K 实测：桌面可见、可遥控播放、弹幕正常。需电视开启开发者模式。

## 已知关键事实

- Flutter 版本约束锁定 3.47.2（pubspec environment）
- 上游 Kazumi 2.3.1 已合入本分支
- 分支含小米电视真机验证记录与 phase-one 交付文档（docs 类提交）

## 进度（2026-09-13）

- ✅ 环境：`.sdk/` 内已装 JDK 17、Android SDK（platform 34/36 等）、Flutter 3.47.2、pub-cache（全部 D 盘隔离）
- ✅ 基线：tv flavor debug APK 构建通过（包名 com.terrowlee.kazumi.tv，label My-Kazumi-TV，leanback 声明齐全）
- ✅ 分支已自带 mobile/tv 双 flavor 与 TV 交互基建（按键路由链、OK 两态、控制栏焦点遍历、选集 tile 自动定位当前集）
- ✅ 改动：`android/app/build.gradle`（flutter_native_splash findProject 守卫）、gradle-wrapper 腾讯镜像、应用名 My-Kazumi-TV、about 页标题
- ✅ 弹幕修复（方案=自定义服务器）：
  - 新设置键 `danmakuApiBaseUrl`（设置→弹幕设置→弹幕服务器）
  - `DanmakuApi.dandanDomain` 解析自定义域名；`DanmakuClient` 仅在官方域名要求签名凭证
  - 凭证缺失提示引导到弹幕服务器设置
  - 凭证到位后：构建时注入 `--dart-define=DANDANAPI_APPID=... --dart-define=DANDANAPI_KEY=...` 并把设置留空即回官方源
- ✅ 阶段E：MainActivity 键码 280–283（ROM 系统导航兼容键）翻译为标准 DPAD；TV 端长按左/右 = MyTVB 式 SeekSession（HUD 预览、松开生效），短按仍 ±arrowKeySkipTime；桌面端行为不变
- ⏳ release arm64 APK 构建中
- 安装方式：adb install（电视开开发者模式）或 U 盘 sideload；构建命令见 AGENTS.md
