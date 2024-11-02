//
//  SyntaxHighlighter.swift
//  FrameWork
//
//  Created by Noah Moller on 11/2/24.
//

import AppKit

class SyntaxHighlighter {
    let textStorage: NSTextStorage
    let language: ProgrammingLanguage
    let defaultAttributes: [NSAttributedString.Key: Any]

    init(textStorage: NSTextStorage, language: ProgrammingLanguage) {
        self.textStorage = textStorage
        self.language = language

        let font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        let textColor = NSColor.textColor
        self.defaultAttributes = [
            .font: font,
            .foregroundColor: textColor
        ]
    }

    func highlight() {
        let text = textStorage.string
        let fullRange = NSRange(location: 0, length: text.utf16.count)

        textStorage.setAttributes(defaultAttributes, range: fullRange)

        applyHighlighting(to: text, in: fullRange)
    }

    private func applyHighlighting(to text: String, in range: NSRange) {
        let keywords = language.keywords
        for keyword in keywords {
            let pattern = "\\b\(keyword)\\b"
            let regex = try? NSRegularExpression(pattern: pattern)
            regex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
                if let matchRange = match?.range {
                    textStorage.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: matchRange)
                }
            }
        }

        let stringPattern = "\".*?\""
        let stringRegex = try? NSRegularExpression(pattern: stringPattern)
        stringRegex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            if let matchRange = match?.range {
                textStorage.addAttribute(.foregroundColor, value: NSColor.systemRed, range: matchRange)
            }
        }

        let commentPattern = "//.*"
        let commentRegex = try? NSRegularExpression(pattern: commentPattern)
        commentRegex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            if let matchRange = match?.range {
                textStorage.addAttribute(.foregroundColor, value: NSColor.gray, range: matchRange)
            }
        }
    }
}


enum ProgrammingLanguage {
    case swift
    case python

    var keywords: [String] {
        switch self {
        case .swift:
            return ["func", "var", "let", "if", "else", "for", "while", "class", "struct", "enum", "import", "return", "public", "private", "extension", "protocol", "guard", "do", "try", "catch", "in", "switch", "case", "break", "continue", "default", "defer", "where"]
        case .python:
            return ["def", "class", "import", "from", "return", "if", "elif", "else", "for", "while", "break", "continue", "pass", "try", "except", "finally", "with", "as", "lambda", "global", "nonlocal", "assert", "yield", "del"]
        }
    }
}

