# FastTranslate

一款极简的 **macOS 划词翻译工具**：选中文本，按快捷键，立即弹出翻译。

基于 [Bob](https://github.com/ripperhe/bob) 的交互理念，只保留「划词翻译」这一个核心功能——纯 Swift 原生实现，无第三方依赖，无需 Xcode。

## 特性

- ⚡ 选中文本 + 快捷键（默认 `⌥D`）→ 弹窗翻译，非激活浮动窗不打断工作
- 🌐 多翻译引擎：**Google（免配置）** / **DeepL** / **DeepSeek**，可在设置中切换
- 🎨 可自定义：快捷键、原文/目标语言、开机自启
- 🧩 协议化引擎设计，新增翻译引擎只需实现一个协议

## 安装

### 方式一：直接使用打包好的 App

1. 打开 `Build/FastTranslate.app`（或拖入「应用程序」文件夹）
2. 首次启动会提示「辅助功能权限」→ 点「打开设置」→ 在 **系统设置 → 隐私与安全性 → 辅助功能** 中勾选 FastTranslate
3. 在任何应用中选中文本，按 `⌥D` 即可翻译

> 若提示"无法打开"，右键 App → 打开（未签名分发需手动确认一次）。

### 方式二：从源码构建

```bash
./build.sh
# 产物：Build/FastTranslate.app
```

## 使用

1. 在任何应用中选中一段文字（浏览器、PDF、编辑器均可）
2. 按下快捷键（默认 `⌥ + D`）
3. 弹窗显示翻译结果，可一键复制

## 翻译引擎

| 引擎 | 是否需要配置 | 说明 |
|------|-------------|------|
| **Google 翻译** | 否 | 默认引擎，开箱即用（非官方接口） |
| **DeepL** | 需要 API Key | 官方接口，翻译质量好，免费额度（[deepl.com](https://www.deepl.com) 注册） |
| **DeepSeek** | 需要 API Key | 中文翻译质量好、成本极低（[platform.deepseek.com](https://platform.deepseek.com) 注册）；可在设置中选择模型（`deepseek-chat` / `deepseek-reasoner` / 自定义）及 API Base 地址 |

在菜单栏图标 → **设置** 中切换引擎并填写 API Key。

## 技术原理

与 Bob 等同类工具一致的 4 步管线：

```
选中文本 → ①监听快捷键 → ②读取选中文本 → ③调用翻译API → ④弹出浮动窗
```

1. **全局快捷键**：Carbon `RegisterEventHotKey`（无需「输入监控」权限）
2. **读取选中文本**：优先**辅助功能 API**（`AXSelectedText`，不碰剪贴板）；读取失败时回退到**模拟 `Cmd+C` 读剪贴板**（备份 → 复制 → 恢复）
3. **翻译 API**：URLSession 异步请求
4. **浮动弹窗**：`NSPanel` 非激活浮动窗，定位在选区附近，永不抢焦点

## 项目结构

```
FastTranslate/
├── Sources/FastTranslate/
│   ├── main.swift                应用入口
│   ├── AppDelegate.swift         菜单栏、权限引导、动作路由
│   ├── HotKeyManager.swift       全局快捷键（Carbon）
│   ├── SelectionReader.swift     读取选中文本（AX + 剪贴板兜底）
│   ├── Config.swift              配置（UserDefaults）
│   ├── LangCode.swift            统一语言代码 → 引擎代码映射
│   ├── Translation/
│   │   ├── Translator.swift      引擎协议 + 错误定义
│   │   ├── GoogleTranslator.swift
│   │   ├── DeepLTranslator.swift
│   │   └── DeepSeekTranslator.swift
│   └── UI/
│       ├── PopupController.swift 浮动弹窗（定位/显示）
│       ├── PopupView.swift       翻译结果视图
│       └── SettingsView.swift    设置界面
├── Build/Info.plist              打包配置（LSUIElement 菜单栏应用）
├── build.sh                      构建脚本（swift build + 打包 + ad-hoc 签名）
└── Package.swift                 Swift Package 配置
```

## 新增翻译引擎

实现 `Translator` 协议 → 在 `TranslatorFactory` 注册 → 在设置界面加一个选项即可：

```swift
struct MyTranslator: Translator {
    var id = "my"
    var displayName = "My 翻译"
    func translate(_ text: String, from: String, to: String) async throws -> String {
        // 调用你的翻译 API
    }
}
```

## 已知限制

- **辅助功能兼容性**：部分应用（网页版 Notion、部分 Electron 应用）读不到选中文本，此时自动回退到剪贴板方案
- **多显示器**：弹窗定位以主屏为基准，边缘场景可能有偏移
- **DeepL/DeepSeek** 需要自备 API Key（都有免费额度）

## 致谢

- 交互理念参考 [Bob](https://github.com/ripperhe/bob)（macOS 翻译/OCR 工具）
