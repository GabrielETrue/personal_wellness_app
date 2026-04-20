import SwiftUI

struct QuickPushView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal)
                .padding(.top)

                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(AppTheme.accentCyan)
                        .shadow(color: AppTheme.accentCyan.opacity(0.5), radius: 8)

                    Text(ParsedInsight.cleanMarkdown(text))
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.accentCyan)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal)
                }

                Spacer()

                Button {
                    UIPasteboard.general.string = text
                    copied = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copied!" : "Copy to Clipboard")
                    }
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.backgroundCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.accentCyan.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
}

#Preview {
    QuickPushView(text: "You've slept poorly three nights in a row — the body keeps the score. Fix the sleep first, everything else follows. Tonight: no screens after 9 PM, in bed by 10. That's your only mission for the next hour.")
        .preferredColorScheme(.dark)
}
