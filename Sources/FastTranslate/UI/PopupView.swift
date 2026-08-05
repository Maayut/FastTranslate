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
        VStack(alignment: .leading, spacing: 10) {
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

            Text(original)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .truncationMode(.tail)

            content
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        )
        .task { await startTranslate() }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("翻译中…").font(.caption).foregroundColor(.secondary)
            }
        case .success(let result):
            ScrollView {
                Text(result)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)
            HStack {
                Spacer()
                Button("复制") { copy(result) }
                Button("关闭", action: onClose)
            }
        case .failure(let message):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                Text(message).font(.caption).foregroundColor(.orange)
            }
            HStack {
                Spacer()
                Button("重试") { Task { await startTranslate() } }
                Button("关闭", action: onClose)
            }
        }
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
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        )
    }
}
