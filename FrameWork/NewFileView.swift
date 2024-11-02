import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct NewFileView: View {
    @State private var fileName: String = ""
    @State private var fileType: FileType = .swift
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var projectDirectoryURL: URL? = nil
    @State private var openedDocument: FileDocument? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("File Name", text: $fileName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Picker("File Type", selection: $fileType) {
                ForEach(FileType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Button(action: {
                createNewFile()
            }) {
                Text("Create New File")
                    .font(.headline)
                    .padding()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("File Creation"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .frame(minWidth: 400, minHeight: 400)
        .onAppear {
            setupKeyCommand()
        }
    }
    
    private func selectProjectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        
        panel.begin { response in
            if response == .OK {
                self.projectDirectoryURL = panel.urls.first
            }
        }
    }
    
    private func setupKeyCommand() {
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "n" {
                NSApp.sendAction(#selector(AppCommands.newFile), to: nil, from: nil)
                return nil
            }
            return event
        }
    }
}

@objc class AppCommands: NSObject {
    @objc static func newFile() {
        if let keyWindow = NSApp.keyWindow, let contentView = keyWindow.contentViewController as? NSHostingController<NewFileView> {
            contentView.rootView = NewFileView()
        } else {
            let newFileWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            newFileWindow.contentViewController = NSHostingController(rootView: NewFileView())
            newFileWindow.makeKeyAndOrderFront(nil)
        }
    }
}

enum FileType: String, CaseIterable {
    case swift = "Swift"
    case swiftUI = "SwiftUI"
    case python = "Python"
    case text = "Text"
    
    var fileExtension: String {
        switch self {
        case .swift, .swiftUI:
            return "swift"
        case .text:
            return "txt"
        case .python:
            return "py"
        }
    }
    
    var templateContent: String {
        switch self {
        case .swift:
            return "//\n//  \(UUID().uuidString).swift\n//  Created using FrameWork\n//\n\nimport Foundation\n\n"
        case .swiftUI:
            return "//\n//  \(UUID().uuidString).swift\n//  Created using FrameWork\n//\n\nimport SwiftUI\n\nstruct ContentView: View {\n    var body: some View {\n        Text(\"Hello, World!\")\n    }\n}\n\nstruct ContentView_Previews: PreviewProvider {\n    static var previews: some View {\n        ContentView()\n    }\n}\n"
        case .text:
            return "//\n//  \(UUID().uuidString).txt\n//  Created using Custom IDE\n//\n\n"
        case .python:
            return ""
        }
    }
}

extension NewFileView {
    private func createNewFile() {
        guard !fileName.isEmpty else {
            alertMessage = "Please enter a file name."
            showAlert = true
            return
        }

        let panel = NSSavePanel()
        panel.title = "Save New File"
        panel.nameFieldStringValue = fileName

        if #available(macOS 11.0, *) {
            switch fileType {
            case .swift, .swiftUI:
                panel.allowedContentTypes = [UTType.swiftSource]
            case .text:
                panel.allowedContentTypes = [UTType.plainText]
            case .python:
                panel.allowedContentTypes = [UTType.pythonScript]
            }
        } else {
            panel.allowedFileTypes = [fileType.fileExtension]
        }

        panel.canCreateDirectories = true
        panel.allowsOtherFileTypes = false

        if let projectDirectoryURL = projectDirectoryURL {
            panel.directoryURL = projectDirectoryURL
        }

        guard let window = NSApplication.shared.windows.first else {
            alertMessage = "No window available to present save panel"
            showAlert = true
            return
        }

        panel.beginSheetModal(for: window) { response in
            if response == .OK, let newFileURL = panel.url {
                do {
                    let content = self.fileType.templateContent
                    try content.write(to: newFileURL, atomically: true, encoding: .utf8)
                    let document = FileDocument(url: newFileURL, content: content, fileType: self.fileType)
                    self.openCodeEditorWindow(for: document)
                } catch {
                    alertMessage = "Failed to create file: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }

    private func openCodeEditorWindow(for document: FileDocument) {
           let codeEditorView = CodeEditorView(document: document)

           let hostingController = NSHostingController(rootView: codeEditorView)
           let window = NSWindow(contentViewController: hostingController)

           window.title = document.fileName
           window.setContentSize(NSSize(width: 800, height: 600))
           window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
           window.makeKeyAndOrderFront(nil)
       }
}
