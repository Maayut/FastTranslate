import SwiftUI
import AppKit
import Carbon.HIToolbox
import ServiceManagement

/// 设置窗口
struct SettingsView: View {
    @AppStorage("engine") private var engine = "google"
    @AppStorage("deeplApiKey") private var deeplApiKey = ""
    @AppStorage("deeplFreePlan") private var deeplFreePlan = true
    @AppStorage("deepSeekApiKey") private var deepSeekApiKey = ""
    @AppStorage("deepSeekModel") private var deepSeekModel = "deepseek-v4-flash"
    @AppStorage("deepSeekBaseURL") private var deepSeekBaseURL = ""
    @AppStorage("sourceLang") private var sourceLang = "auto"
    @AppStorage("targetLang") private var targetLang = "zh"
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    @State private var isRecording = false
    @State private var recordingMonitor: Any?
    @State private var hotkeyDisplay = HotKeyManager.shared.currentDisplay

    var body: some View {
        Form {
            Section("翻译引擎") {
                Picker("引擎", selection: $engine) {
                    ForEach(TranslatorFactory.options, id: \.id) { opt in
                        Text(opt.display).tag(opt.id)
                    }
                }
                if engine == "deepl" {
                    SecureField("DeepL API Key", text: $deeplApiKey)
                    Toggle("使用免费版（api-free.deepl.com）", isOn: $deeplFreePlan)
                }
                if engine == "deepseek" {
                    SecureField("DeepSeek API Key", text: $deepSeekApiKey)
                    Text("DeepSeek 平台：platform.deepseek.com 申请")
                        .font(.caption).foregroundColor(.secondary)

                    HStack {
                        TextField("模型（默认 deepseek-v4-flash）", text: $deepSeekModel)
                        Menu {
                            Button("deepseek-v4-flash（推荐，快）") { deepSeekModel = "deepseek-v4-flash" }
                            Button("deepseek-v4-pro（深度思考）") { deepSeekModel = "deepseek-v4-pro" }
                        } label: {
                            Image(systemName: "chevron.up.chevron.down")
                        }
                    }
                    Text("v4-flash 翻译快又便宜；v4-pro 会深度思考，翻译不推荐。旧模型名 deepseek-chat/reasoner 已下线")
                        .font(.caption).foregroundColor(.secondary)

                    TextField("API Base（可选，默认 api.deepseek.com）", text: $deepSeekBaseURL)
                        .textFieldStyle(.roundedBorder)
                    Text("留空用官方接口；可填第三方 OpenAI 兼容中转地址")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            Section("语言") {
                Picker("原文语言", selection: $sourceLang) {
                    ForEach(LangCode.all, id: \.code) { Text($0.display).tag($0.code) }
                }
                Picker("目标语言", selection: $targetLang) {
                    ForEach(LangCode.all.filter { $0.code != "auto" }, id: \.code) { Text($0.display).tag($0.code) }
                }
            }

            Section("快捷键") {
                HStack {
                    Text("划词翻译快捷键")
                    Spacer()
                    Button(isRecording ? "请按下新的快捷键…" : hotkeyDisplay) {
                        isRecording.toggle()
                    }
                    .buttonStyle(.bordered)
                }
                Text("先选中文本，再按快捷键触发翻译")
                    .font(.caption).foregroundColor(.secondary)
            }
            .onChange(of: isRecording) { _, recording in
                if recording { startRecording() } else { stopRecording() }
            }

            Section("通用") {
                Toggle("开机自启", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in
                        applyLaunchAtLogin(on)
                    }
                Text("提示：若开机自启失败，请把 FastTranslate.app 移到「应用程序」文件夹后重试。")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 460, height: 560)
    }

    // MARK: - 快捷键录制

    private func startRecording() {
        recordingMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
            // 必须带修饰键，避免吞掉普通按键
            guard !modifiers.isEmpty else { return event }

            let code = Int(event.keyCode)
            let mods = carbonModifiers(from: modifiers)
            Config.hotKeyCode = code
            Config.hotKeyModifiers = mods
            HotKeyManager.shared.register(keyCode: code, modifiers: mods)
            hotkeyDisplay = HotKeyManager.shared.currentDisplay
            DispatchQueue.main.async { isRecording = false }
            return nil
        }
    }

    private func stopRecording() {
        if let monitor = recordingMonitor {
            NSEvent.removeMonitor(monitor)
            recordingMonitor = nil
        }
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> Int {
        var value = 0
        if flags.contains(.command) { value |= Int(cmdKey) }
        if flags.contains(.option) { value |= Int(optionKey) }
        if flags.contains(.control) { value |= Int(controlKey) }
        if flags.contains(.shift) { value |= Int(shiftKey) }
        return value
    }

    // MARK: - 开机自启

    private func applyLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // 静默失败；界面上已有"移到应用程序"的提示
        }
    }
}
