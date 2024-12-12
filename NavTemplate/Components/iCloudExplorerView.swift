import SwiftUI

struct iCloudExplorerView: View {
    @State private var files: [URL] = []
    @State private var errorMessage: String?
    @State private var selectedContent: String?
    
    var body: some View {
        VStack {
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }
            
            List(files, id: \.self) { url in
                VStack(alignment: .leading) {
                    Text(url.lastPathComponent)
                        .font(.headline)
                    if let isDirectory = try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory {
                        Text(isDirectory ? "Folder" : "File")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .onTapGesture {
                    if url.pathExtension == "md" {
                        do {
                            selectedContent = try String(contentsOf: url, encoding: .utf8)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
            
            if let content = selectedContent {
                ScrollView {
                    Text(content)
                        .padding()
                }
                .frame(maxHeight: 200)
            }
        }
        .navigationTitle("Obsidian Vault")
        .onAppear {
            accessObsidianVault()
        }
    }
    
    func accessObsidianVault() {
        let obsidianURL = URL(string: "file:///private/var/mobile/Library/Mobile%20Documents/iCloud~md~obsidian/")!
        
        do {
            // List contents
            let contents = try FileManager.default.contentsOfDirectory(
                at: obsidianURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: .skipsHiddenFiles
            )
            
            // Filter for markdown files and folders
            files = contents.filter { url in
                let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
                return isDirectory || url.pathExtension == "md"
            }
            
            // Read a specific file
            if let firstMD = files.first(where: { $0.pathExtension == "md" }) {
                let content = try String(contentsOf: firstMD, encoding: .utf8)
                print("File contents: \(content)")
            }
            
        } catch {
            errorMessage = error.localizedDescription
            print("Error accessing Obsidian vault: \(error)")
        }
    }
}
