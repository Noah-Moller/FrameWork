//
//  CodeEditorView.swift
//  FrameWork
//
//  Created by Noah Moller on 11/2/24.
//

import SwiftUI
import AppKit

struct LineNumberedTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var lineCount: Int
    let language: ProgrammingLanguage

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()

        textView.isEditable = true
        textView.delegate = context.coordinator
        textView.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.backgroundColor = NSColor.clear
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.textContainer?.lineFragmentPadding = 0

        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textView.replaceTextContainer(textContainer)

        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
            .foregroundColor: NSColor.textColor
        ]
        let attributedString = NSAttributedString(string: text, attributes: defaultAttributes)
        textStorage.setAttributedString(attributedString)

        let syntaxHighlighter = SyntaxHighlighter(textStorage: textStorage, language: language)
        context.coordinator.syntaxHighlighter = syntaxHighlighter
        syntaxHighlighter.highlight()

        context.coordinator.textStorage = textStorage

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? NSTextView,
           let textStorage = context.coordinator.textStorage {

            if textStorage.string != text {
                let defaultAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
                    .foregroundColor: NSColor.textColor
                ]
                let attributedString = NSAttributedString(string: text, attributes: defaultAttributes)
                textStorage.setAttributedString(attributedString)

                context.coordinator.syntaxHighlighter?.highlight()
            }
            DispatchQueue.main.async {
                self.lineCount = textView.calculateLineCount()
            }
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: LineNumberedTextEditor
        var syntaxHighlighter: SyntaxHighlighter?
        var textStorage: NSTextStorage?

        init(_ parent: LineNumberedTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                self.parent.text = textView.string
                DispatchQueue.main.async {
                    self.parent.lineCount = textView.calculateLineCount()
                    self.syntaxHighlighter?.highlight()
                }
            }
        }
    }
}

extension NSTextView {
    func calculateLineCount() -> Int {
        guard let layoutManager = self.layoutManager, let textContainer = self.textContainer else {
            return 0
        }
        layoutManager.ensureLayout(for: textContainer)
        let numberOfGlyphs = layoutManager.numberOfGlyphs
        var index = 0
        var lineRange = NSRange()
        var numberOfLines = 0

        while index < numberOfGlyphs {
            layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange, withoutAdditionalLayout: true)
            index = NSMaxRange(lineRange)
            numberOfLines += 1
        }
        return numberOfLines
    }
}

struct CodeEditorView: View {
    @ObservedObject var document: FileDocument
    @State private var lineCount: Int = 1

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(1...max(self.lineCount, 1), id: \.self) { line in
                        Text("\(line)")
                            .font(.system(size: NSFont.systemFontSize))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .padding(.horizontal, 4)
                            .frame(height: self.lineHeight(), alignment: .topTrailing)
                    }
                    Spacer()
                }
            }
            .padding(.top, 2)
            .background(Color(NSColor.textBackgroundColor))

            Divider()

            LineNumberedTextEditor(text: $document.content, lineCount: $lineCount, language: document.fileType.programmingLanguage)
                .frame(minHeight: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    func lineHeight() -> CGFloat {
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        return font.ascender + abs(font.descender) + font.leading
    }
}
