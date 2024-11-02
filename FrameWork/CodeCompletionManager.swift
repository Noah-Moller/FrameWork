//
//  CodeCompletionManager.swift
//  FrameWork
//
//  Created by Noah Moller on 11/2/24.
//

import Foundation
import AppKit
import SwiftUI

class CodeCompletionManager {
    let textView: NSTextView
    let language: ProgrammingLanguage
    var completionWindow: NSWindow?
    var completionList: [String] = []

    init(textView: NSTextView, language: ProgrammingLanguage) {
        self.textView = textView
        self.language = language
    }

    func showCompletions(prefix: String, at location: NSPoint) {
        completionList = language.keywords.filter { $0.hasPrefix(prefix) }
        
        let keywordCompletions = language.keywords.filter { $0.hasPrefix(prefix) }
           let snippetCompletions = language.snippets.filter { $0.trigger.hasPrefix(prefix) }.map { $0.trigger }
           completionList = keywordCompletions + snippetCompletions

        if completionList.isEmpty {
            hideCompletions()
            return
        }

        let completionView = CompletionListView(completions: completionList, selectCompletion: { [weak self] completion in
            self?.insertCompletion(completion, prefix: prefix)
            self?.hideCompletions()
        })

        let hostingView = NSHostingView(rootView: completionView)
        let window = NSWindow(contentViewController: NSViewController())
        window.contentView = hostingView
        window.styleMask = [.borderless]
        window.level = .floating
        window.setFrameOrigin(location)
        window.makeKeyAndOrderFront(nil)

        completionWindow = window
    }

    func hideCompletions() {
        completionWindow?.close()
        completionWindow = nil
    }

    func insertCompletion(_ completion: String, prefix: String) {
        guard let selectedRange = textView.selectedRanges.first?.rangeValue else { return }
        let start = selectedRange.location - prefix.count
        let range = NSRange(location: start, length: prefix.count)

        if let snippet = language.snippets.first(where: { $0.trigger == completion }) {
            insertSnippet(snippet, at: range)
        } else {
            textView.replaceCharacters(in: range, with: completion)
        }
    }

    func insertSnippet(_ snippet: CodeSnippet, at range: NSRange) {
        let template = snippet.template.replacingOccurrences(of: "\\$\\{\\d+:?[^}]*\\}", with: "", options: .regularExpression)
        textView.replaceCharacters(in: range, with: template)
    }
}

