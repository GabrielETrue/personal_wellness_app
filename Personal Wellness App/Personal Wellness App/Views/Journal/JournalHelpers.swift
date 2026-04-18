import SwiftUI

func moodEmoji(_ mood: Int) -> String? {
    switch mood {
    case 1: return "😞"
    case 2: return "😕"
    case 3: return "😐"
    case 4: return "🙂"
    case 5: return "😄"
    default: return nil
    }
}

struct MoodSelectorRow: View {
    @Binding var selectedMood: Int

    private let moods = [1, 2, 3, 4, 5]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(moods, id: \.self) { value in
                Button {
                    selectedMood = (selectedMood == value) ? 0 : value
                } label: {
                    Text(moodEmoji(value) ?? "")
                        .font(.title2)
                        .padding(8)
                        .background(
                            selectedMood == value
                                ? Color.accentColor.opacity(0.2)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
