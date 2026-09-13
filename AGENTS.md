# AGENTS.md — My-Kazumi-TV

供任何 AI 助手/开发者在新会话中直接接手本项目。详细计划见 `PROJECT_PLAN.md`。

## 项目一句话

基于 znbsf/Kazumi 分支 `codex/tv-phase1-hardening`，为 Sony 85X90K（Google TV）定制：TV 桌面可见（leanback）、弹幕可获取（弹弹play v2 API）、遥控器交互按 MyTVB 模式移植。应用名 **My-Kazumi-TV**。

## 环境（全部隔离在 `.sdk/`，不污染系统；uv 不适用于此类工具）

```
JAVA_HOME=D:\python\code\My-Kazumi-TV\.sdk\jdk17
ANDROID_HOME=D:\python\code\My-Kazumi-TV\.sdk\android-sdk
PATH+= .sdk\flutter\bin; .sdk\android-sdk\platform-tools
```
构建前在 Git Bash 中 export 上述变量。已安装：platform-tools、platforms;android-36、build-tools;36.0.0。

## 网络注意事项（本机为受限网络）

- 直连 `github.com` 的 git 操作会被 reset；`storage.googleapis.com` 慢
- 可用镜像：
  - Flutter SDK / pub 镜像：`https://storage.flutter-io.cn`（约 20MB/s）
  - 构建 pub 依赖时必须设置 `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn` 与 `PUB_HOSTED_URL=https://pub.flutter-io.cn`
  - JDK：`https://mirrors.tuna.tsinghua.edu.cn/Adoptium/`
  - Gradle wrapper 发行包：`https://mirrors.cloud.tencent.com/gradle/`（已写入 gradle-wrapper.properties）
  - GitHub tarball/raw：`https://ghfast.top/https://github.com/<owner>/<repo>/...` 或 codeload.github.com 直连
  - git 依赖用环境变量重写（勿改全局 git 配置）：
    `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.https://ghfast.top/https://github.com/.insteadOf" GIT_CONFIG_VALUE_0="https://github.com/"`
- 本机有 `D:\v2rayN-Core` 但代理未启动；不要假设 127.0.0.1:10808 可用

## 构建 Windows 踩坑记录（重要）

0. **必须用 --split-per-abi 构建 TV 包**：`flutter build apk --flavor tv --target-platform android-arm64` 会产出"残缺胖包"（media-kit 等插件把三个 ABI 的 so 都放进 APK，但 libflutter.so/libapp.so 只有 arm64），在 32 位用户空间的电视上会安装成功但启动即崩。Sony 部分型号是 64 位硬件 + 32 位用户空间。交付时同时提供 arm64 与 armeabi-v7a 两个包。

1. **PUB_CACHE 必须与项目同盘**：pub 缓存默认在 `C:\Users\terro\AppData\Local\Pub\Cache`，与 D 盘项目跨盘会导致 Gradle 报
   "this and base files have different roots"。构建前必须 `export PUB_CACHE=D:\python\code\My-Kazumi-TV\.sdk\pub-cache` 并重新 `flutter pub get`。
2. **media-kit libmpv jar 预下载**：`media_kit_libs_android_video` 的 build.gradle 在**配置期**从 GitHub 下载 libmpv jar。
   预下载地址为 `D:\python\code\My-Kazumi-TV\build\media_kit_libs_android_video\v1.2.7\`（注意：rootProject.buildDir='../build'，
   各子项目 buildDir=`<root>/build/<name>`，不是 pub cache 里插件自身的 build 目录）。4 个 jar 的 SHA-256 与脚本内置值一致即可跳过网络。
3. **android/app/build.gradle 中 `:flutter_native_splash` 用 findProject 守卫**（dev 插件在 debug 构建不是 Gradle 子项目）。
4. flutter analyze 在 Windows 上需要开发者模式（符号链接）；当前机器未开启，只影响 analyze symlink 阶段，不影响构建。
5. 完整构建环境变量见 PROJECT_PLAN.md；构建命令：
   `flutter build apk --flavor tv --target-platform android-arm64`（debug 加 `--debug`）

## 弹幕服务器对接（danmu_api 兼容服务）

- 应用设置项：设置 → 弹幕设置 → **弹幕服务器**（`SettingsKeys.danmakuApiBaseUrl`），留空 = 官方 api.dandanplay.net（要求构建注入凭证）
- 自定义服务器需兼容弹弹play v2 接口：`/api/v2/search/episodes`、`/api/v2/bangumi/{id}`、`/api/v2/comment/{episodeId}`，返回弹弹play JSON（`comments` 数组）
- [danmu_api](https://github.com/huangxd-/danmu_api) 部署若设置了 TOKEN，路径形式为 `https://host/{TOKEN}`——把**含 token 段的完整路径**填进弹幕服务器设置即可（应用会在其后拼接 `/api/v2/...`）
- 已知限制：官方的 `/api/v2/bangumi/bgmtv/{bgmId}` 自动匹配端点 danmu_api 不支持，自动匹配会失败，需用手动搜索选集
- 公共实例（danmu.autos、woaiybl.asia）都设了私有 TOKEN，不可用；自部署是唯一无凭证途径（Vercel/Cloudflare/Node 均可）
- TV 设置页 Slider 焦点：全局 `NavigationMode.directional`（app_widget.dart builder），否则 Slider 吞掉上下键造成焦点陷阱
- 搜索直连修正（v2）：bgm.tv 系域名在全国范围被 DNS 污染（阿里 DoH 也返回假 IP），直连必死。正确架构：`api.kazumi.fyi` 镜像的 p1 接口（详情/时间线）**不需要签名**，开箱即用；仅搜索（POST /v0/search/subjects）强制签名（KAZUMI_APPID，仅上游 CI 有）。无凭证构建的搜索由拦截器改走社区 v0 反代 `https://bgmapi.anibt.net`（ApiEndpoints.bangumiSearchMirrorDomain，实测可用，图片走 bgmimg.anibt.net）。已知残留：p1 评论接口镜像要求签名（401）、详情封面图指向被墙的 api.bgm.tv，两者在无凭证构建下不可用
- 社区已知 Bangumi 反代：bgmapi.anibt.net（v0，实测可用）、bangumi.lol（本网络不可达）；kazumi.fyi 凭证无公开申请渠道
- chinasoul/BT 的"二维码搜索"实为 B 站扫码登录（源码未公开，仓库只有 README）；MyTVB 二维码同为扫码登录，文本输入是自绘 T9/QWE 键盘（KeyboardView.kt）
- TV 左栏"我的"= outlet 跳 `/tab/my/` + **根导航器 pushNamed('/settings/')**（menu.dart `_selectDestination`）。不要用 outlet.navigate('/settings/')——settings 模块的子路由在 outlet 上下文中失灵（磁贴点了没反应）
- 首页 TV 卡片：`BangumiCardV.posterAspectRatio`（TV 0.75，其他端 0.65），卡片按高度定宽，调比例即调宽度/间距
- 分类行最左再按左 = `TvFocusRailIntent` 跳侧栏（不回绕到最后一个分类）
- IME 收起后 TextField 仍持有焦点导致方向键卡死：TvAppShell 的 `didChangeMetrics` 在键盘收起时对可编辑焦点 unfocus
- 二维码输入（仿 chinasoul/BT）：`lib/services/tv/qr_input_service.dart` 在 TV 端起局域网 HTTP 服务（端口 18765 起），二维码指向 `http://<tv-ip>:<port>/?t=<id>`；手机网页输入回传 → 目标控制器 + 自动提交。通用面板组件：`lib/bean/widget/tv_qr_input_panel.dart`（TV-only），已接入：搜索对话框（自动提交）、弹幕服务器地址、播放设置数字参数（仅填入，需按确定）
- TV 左栏的"遥控器"入口已按用户要求移除（menu.dart rail 项 + router.dart tvMenu 条目；/remote-help 路由仍注册但无入口）
- 设置滑条 TV 交互：SettingsSliderTile 改为行聚焦（行上左右键调值、上下键走焦点遍历），Slider 本身不持有焦点；**不要**全局开 `NavigationMode.directional`——它会破坏设置页磁贴的焦点遍历

## 播放卡顿真相（2026-09-13 定位）

- **主因**：media_kit 安卓端视频输出只有 SurfaceTexture / SurfaceProducer 两条 Flutter 纹理路径，**没有原生 SurfaceView 直出**——每帧视频都经 Flutter 光栅线程全屏合成（4K 大纹理），UI 与视频挤同一条管线。这与解码方式无关，所以"软解硬解都卡、整个播放界面也卡"。MyTVB/BLBL 原生 Media3 + SurfaceView 硬件 overlay 不占 Flutter 管线，故不卡。
- **缓解开关**：`SettingsKeys.androidSurfaceProducer`（默认 false=上游行为），开启后走 Flutter SurfaceProducer（API 29+ AImageReader/HardwareBuffer），每帧合成开销显著更低。入口：设置→视频渲染器→实验性。media_kit 该参数默认 true，本分支曾硬编码 false。
- 软解降载：Android 强制 mpv `vd-lavc-fast=yes`（硬解无影响）。
- 64 位：X90K 系统用户空间 32 位（arm64 包安装器拒绝），系统限制无解；32 位软解 4K HEVC 吃力是 CPU 硬约束。
- 用户实测：低内存开关与卡顿无关（已排除缓存假设）；弹幕未配置时也卡（已排除弹幕假设）。
- 设置页搜索框已移除（规则仓库/我的规则页），TV 上输入法+焦点处理过重。

## 源码获取方式

本仓库源码以 tarball 方式取得（分支 `codex/tv-phase1-hardening`，2026-09-13），如需 git 历史可用 ghfast 镜像重推。上游更新检查：对比分支 HEAD 提交（2026-09-12: 54c8663）。

## 关键代码位置（上游 Kazumi 结构）

- 弹幕：`lib/request/apis/danmaku_api.dart`、`lib/request/config/api_endpoints.dart`
- TV 焦点基建：`lib/bean/widget/tv_focusable_surface.dart`
- Android 清单：`android/app/src/main/AndroidManifest.xml`
- 应用名本地化：`lib/l10n/`（arb 文件）

## 里程碑

A 环境 → B 基线 debug APK → C leanback+改名+release APK → D 弹幕修复 → E MyTVB 遥控器交互（按键路由链/OK 两态/IPTV 切台/SeekSession/焦点恢复/键码 280–283）。
