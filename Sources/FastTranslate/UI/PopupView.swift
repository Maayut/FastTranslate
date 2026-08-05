import SwiftUI
import AppKit

/// 翻译结果弹窗内容
struct PopupView: View {
    let original: String
    let onClose: () -> Void

    @State private var state: LoadState = .loading

    enum LoadState {
        case loading
        case success(String)
        case failure(String)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 顶栏
            HStack(spacing: 6) {
                Image(systemName: "character.book.closed")
                    .foregroundColor(.secondary)
                Text("FastTranslate")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }

            // 译文：主内容区（占满可用空间）
            Group {
                switch state {
                case .loading:
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text("翻译中…").font(.caption).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                case .success(let result):
                    ScrollView {
                        Text(result)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failure(let message):
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        Text(message).font(.caption).foregroundColor(.orange)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }

            // 原文：底部小字（翻译成功后显示）
            if case .success = state {
                Text("原文：\(original)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }

            // 操作按钮
            switch state {
            case .success(let result):
                HStack {
                    Spacer()
                    Button("复制译文") { copy(result) }
                    Button("关闭", action: onClose)
                }
            case .failure:
                HStack {
                    Spacer()
                    Button("重试") { Task { await startTranslate() } }
                    Button("关闭", action: onClose)
                }
            case .loading:
                EmptyView()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        )
        .task { await startTranslate() }
    }

    private func startTranslate() async {
        state = .loading
        do {
            let result = try await TranslationService.translate(original)
            state = .success(result)
        } catch {
            state = .failure(error.localizedDescription)
        }
    }

    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

/// 纯消息弹窗内容
struct MessageView: View {
    let message: String
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.magnifyingglass")
                .font(.title2)
                .foregroundColor(.secondary)
            Text(message)
                .font(.callout)
            Button("知道了", action: onClose)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        )
    }
}
