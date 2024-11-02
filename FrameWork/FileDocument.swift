//
//  FileDocument.swift
//  FrameWork
//
//  Created by Noah Moller on 11/2/24.
//

import SwiftUI
import Combine

class FileDocument: ObservableObject {
    @Published var content: String {
        didSet {
            saveContent()
        }
    }
    var url: URL
    var fileName: String
    var fileType: FileType
    
    init(url: URL, content: String, fileType: FileType) {
        self.url = url
        self.content = content
        self.fileType = fileType
        self.fileName = url.lastPathComponent
    }
    private func saveContent() {
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save content: \(error)")
        }
    }
}

extension FileType {
    var programmingLanguage: ProgrammingLanguage {
        switch self {
        case .swift, .swiftUI:
            return .swift
        case .python:
            return .python
        case .text:
            return .swift
        }
    }
}



