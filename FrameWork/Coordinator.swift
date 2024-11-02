//
//  Coordinator.swift
//  FrameWork
//
//  Created by Noah Moller on 11/2/24.
//

import SwiftUI
import AppKit

class Coordinator: NSObject, NSTextViewDelegate {
    var parent: LineNumberedTextEditor
    var syntaxHighlighter: SyntaxHighlighter?
    var codeCompletionManager: CodeCompletionManager?

    init(_ parent: LineNumberedTextEditor) {
        self.parent = parent
    }

    func textDidChange(_ notification: Notification) {
        if let textView = notification.object as? NSTextView {
            self.parent.text = textView.string
            DispatchQueue.main.async {
                self.parent.lineCount = textView.calculateLineCount()
                self.syntaxHighlighter?.highlight()
                self.handleCodeCompletion(in: textView)
            }
        }
    }

    private func handleCodeCompletion(in textView: NSTextView) {
        guard let selectedRange = textView.selectedRanges.first?.rangeValue else { return }
        let cursorPosition = selectedRange.location
        let text = textView.string as NSString

        let regex = try! NSRegularExpression(pattern: "\\w+$")
        let range = NSRange(location: 0, length: cursorPosition)
        let matches = regex.matches(in: text as String, options: [], range: range)

        guard let match = matches.last else {
            codeCompletionManager?.hideCompletions()
            return
        }

        let prefixRange = match.range
        let prefix = text.substring(with: prefixRange)

        let glyphIndex = textView.layoutManager?.glyphIndexForCharacter(at: cursorPosition) ?? 0
        let boundingRect = textView.layoutManager?.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 0), in: textView.textContainer!) ?? .zero
        let textViewOrigin = textView.frame.origin
        let location = NSPoint(x: textViewOrigin.x + boundingRect.origin.x, y: textViewOrigin.y + boundingRect.origin.y - boundingRect.size.height)

        if codeCompletionManager == nil {
            codeCompletionManager = CodeCompletionManager(textView: textView, language: parent.language)
        }
        codeCompletionManager?.showCompletions(prefix: prefix, at: location)
    }
}

extension ProgrammingLanguage {
    var snippets: [CodeSnippet] {
        switch self {
        case .swift:
            return [
                CodeSnippet(trigger: "func", template: "func ${1:functionName}(${2:parameters}) -> ${3:ReturnType} {\n    ${0}\n}"),
            ]
        case .python:
            return [
                CodeSnippet(trigger: "def", template: "def ${1:function_name}(${2:params}):\n    ${0}")
            ]
        }
    }
}

struct CodeSnippet {
    let trigger: String
    let template: String
}


