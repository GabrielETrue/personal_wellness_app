import Foundation

struct InsightSection: Identifiable {
    let id = UUID()
    let header: String
    let content: String
    let isQuote: Bool
}

struct ParsedInsight {
    let sections: [InsightSection]

    static func parse(_ raw: String) -> ParsedInsight {
        let knownHeaders = [
            "QUOTE:",
            "REFLECTION:",
            "PROGRESS RECAP:",
            "WINS TODAY:",
            "FOCUS AREAS:",
            "YOUR MISSION TODAY:",
            "SUGGESTED ADJUSTMENT:"
        ]

        var sections: [InsightSection] = []
        var currentHeader = ""
        var currentContent: [String] = []

        let lines = raw.components(separatedBy: "\n")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if let header = knownHeaders.first(where: { trimmed.hasPrefix($0) }) {
                if !currentHeader.isEmpty {
                    sections.append(InsightSection(
                        header: currentHeader,
                        content: currentContent
                            .joined(separator: "\n")
                            .trimmingCharacters(in: .whitespacesAndNewlines),
                        isQuote: currentHeader == "QUOTE:"
                    ))
                }
                currentHeader = header
                let afterHeader = trimmed
                    .dropFirst(header.count)
                    .trimmingCharacters(in: .whitespaces)
                currentContent = afterHeader.isEmpty ? [] : [String(afterHeader)]
            } else if !currentHeader.isEmpty {
                currentContent.append(trimmed)
            }
        }

        if !currentHeader.isEmpty {
            sections.append(InsightSection(
                header: currentHeader,
                content: currentContent
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                isQuote: currentHeader == "QUOTE:"
            ))
        }

        return ParsedInsight(sections: sections)
    }

    static func cleanMarkdown(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(
            of: "\\*\\*(.+?)\\*\\*",
            with: "$1",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "\\*(.+?)\\*",
            with: "$1",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "^\\s*[-•*]\\s+",
            with: "• ",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
