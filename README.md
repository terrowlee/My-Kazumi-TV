<div align="center">
  <img src="static/tv-mark.svg" alt="My-Kazumi-TV" width="144">
  <h1>My-Kazumi-TV</h1>
  <p>基于 Kazumi 的 Android TV / Google TV 定制版，为电视大屏与遥控器深度优化。</p>
</div>

My-Kazumi-TV 基于 [Predidit/Kazumi](https://github.com/Predidit/Kazumi) 与
[znbsf/Kazumi](https://github.com/znbsf/Kazumi) 的 TV 适配分支（`codex/tv-phase1-hardening`）定制，
在电视焦点交互、弹幕与搜索可用性、播放稳定性上做了大量修改，源码沿用 GPL-3.0。

## 主要定制点

### 电视适配与遥控器

- 应用名 **My-Kazumi-TV**，独立包名 `com.znbsf.kazumi.tv`，带 TV Banner，
  可与手机版共存，出现在 Google TV 桌面
- 部分电视 ROM 的系统导航兼容键码（280–283）在原生层翻译为标准方向键
- 播放中**长按左/右键 = SeekSession**：HUD 实时预览目标位置，松开才跳转；短按仍为快进/快退
- 设置页焦点高亮（主题色边框 + 填充），多选一设置改为**弹出选择**，
  移除冗余的返回/关闭按钮与装饰性横幅
- 部分电视系统用户空间为 32 位（如 Sony X90K），提供 `armeabi-v7a` 包

### 弹幕与搜索可用性

- **自定义弹幕服务器**：设置 → 弹幕设置 → 弹幕服务器，可指向任意弹弹play 兼容服务
  （如自部署的 [danmu_api](https://github.com/huangxd-/danmu_api)），无需官方凭证；
  构建时注入 `DANDANAPI_APPID` / `DANDANAPI_KEY` 则使用官方弹弹play 源
- **搜索免凭证**：官方 Bangumi 镜像的搜索接口需要签名凭证，开源自编译构建自动改走
  社区 v0 反代（条目详情等其余接口不受影响）
- 二维码输入：搜索框与设置对话框旁显示二维码，手机扫码打开局域网页面直接打字，
  回传到电视自动搜索（无需任何外部服务）

### 播放稳定性

- 观看历史只在**暂停/退出/切集**时写入数据库，避免电视闪存上周期性写库导致的整机冻结
- Hive 压缩阈值调优；软件解码强制 `vd-lavc-fast` 降低 32 位 CPU 负担
- `SurfaceProducer` 合成管线实验开关（设置 → 视频渲染器）

### 输入与体验

- 整体缩放：界面设置 → 显示大小，75%–150% 全局等比缩放
- 二维码输入面板、TV 端移除触摸滑动手势等

## 下载与安装

到 [Releases](https://github.com/terrowlee/My-Kazumi-TV/releases) 页面下载，
或按下方说明从源码构建。

| 包 | 适用 |
| --- | --- |
| `*-arm64-v8a.apk` | 64 位用户空间的电视/盒子 |
| `*-armeabi-v7a.apk` | 32 位用户空间的电视/盒子（Sony X90K 等常见） |

安装方式二选一：

1. **adb**：电视开启开发者模式与网络调试后 `adb connect <电视IP>:5555`，
   再 `adb install <apk>`；
2. **U 盘侧载**：把 APK 拷入 U 盘，用电视自带文件管理器安装（允许未知来源）。

## 从源码构建

- Flutter **3.47.2**（pubspec 锁定）、JDK 17、Android SDK
- 国内网络建议设置镜像环境变量：
  ```bash
  export PUB_HOSTED_URL=https://pub.flutter-io.cn
  export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
  ```
- 构建命令：
  ```bash
  flutter build apk --release --flavor tv --split-per-abi
  ```
  产物在 `build/app/outputs/flutter-apk/`。注意**不要**使用
  `--target-platform android-arm64` 构建单个胖包——那样产出的包在 32 位
  用户空间的电视上能安装但无法启动。

## 已知限制

- 弹弹play 官方源需要开发者凭证（`--dart-define` 注入），未配置时请在设置中
  指向自建弹幕服务
- Bangumi 镜像的评论接口需要签名凭证，开源自编译构建的**评论**功能可能不可用
  （搜索、条目详情、播放不受影响）

## 致谢

- [Predidit/Kazumi](https://github.com/Predidit/Kazumi) — 上游项目
- [znbsf/Kazumi](https://github.com/znbsf/Kazumi) — TV 适配分支基础
- [MyTVB](https://github.com/qianxuntudou-ops/MyTVB) — 遥控器交互与弹幕引擎参考
- [huangxd-/danmu_api](https://github.com/huangxd-/danmu_api) — 自建弹幕服务推荐
- [media-kit](https://github.com/media-kit/media-kit)、
  [canvas_danmaku](https://pub.dev/packages/canvas_danmaku) 等开源组件

## 许可

本项目沿用 [GPL-3.0](LICENSE) 协议。
