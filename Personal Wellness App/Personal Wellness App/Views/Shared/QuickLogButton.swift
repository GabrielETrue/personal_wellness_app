import SwiftUI

struct QuickLogButton: View {
    @Binding var isPresented: Bool

    var body: some View {
        Button { isPresented = true } label: {
            VStack(spacing: 2) {
                Image(systemName: "plus")
                    .font(.title2).fontWeight(.bold)
                Text("Log")
                    .font(.caption2).fontWeight(.semibold)
            }
            .foregroundStyle(AppTheme.textPrimary)
            .frame(width: 64, height: 64)
            .background(AppTheme.xpGradient)
            .clipShape(Circle())
            .shadow(color: AppTheme.accentBlue.opacity(0.4), radius: 12)
        }
    }
}
