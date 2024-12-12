import SwiftUI

struct iCloudPage: Page {
    @StateObject private var vaultAccess = ObsidianVaultAccess.shared
    @State private var showVaultPicker = false
    @State private var selectedContent: String?
    @State private var selectedFile: URL?
    @State private var currentDirectory: URL?
    @State private var shouldRefresh = false
    
    var navigationManager: NavigationManager?
    var widgets: [AnyWidget] { [] }
    
    // Add this struct for file preview
    private struct FilePreview: Identifiable {
        let url: URL
        let content: String
        var id: String { url.absoluteString }
    }
    
    // Change selectedFile to FilePreview
    @State private var selectedPreview: FilePreview?
    
    func makeMainContent() -> AnyView {
        AnyView(
            VStack(spacing: 0) {
                // Navigation bar with back button
                HStack {
                    Button("Go Back") {
                        navigationManager?.navigateBack()
                    }
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                
                // Main content
                VStack {
                    if vaultAccess.isVaultAccessible {
                        VStack(spacing: 16) {
                            // Show current path
                            if let currentDir = currentDirectory {
                                HStack {
                                    Button("← Back") {
                                        currentDirectory = currentDir.deletingLastPathComponent()
                                    }
                                    Spacer()
                                    Text(currentDir.lastPathComponent)
                                        .font(.headline)
                                }
                                .padding(.horizontal)
                            } else {
                                HStack {
                                    Text("Vault: \(vaultAccess.vaultName ?? "")")
                                        .font(.headline)
                                    Spacer()
                                    Button {
                                        print("Button pressed")
                                        let success = vaultAccess.createMarkdownFile(
                                            named: "Test.md",
                                            content: "# Hello World",
                                            in: currentDirectory
                                        )
                                        if success {
                                            shouldRefresh.toggle()
                                        }
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                            .frame(width: 44, height: 44)  // Minimum tap target size
                                    }
                                    .buttonStyle(BorderlessButtonStyle())  // Prevent tap gesture conflicts
                                    .contentShape(Rectangle())  // Make entire frame tappable
                                }
                                .padding(.horizontal)
                            }
                            
                            if let items = vaultAccess.listVaultItems(in: currentDirectory) {
                                if items.isEmpty {
                                    Text("Empty folder")
                                        .foregroundColor(.gray)
                                } else {
                                    ScrollView {
                                        LazyVStack(alignment: .leading, spacing: 12) {
                                            ForEach(items) { item in
                                                HStack {
                                                    VStack(alignment: .leading) {
                                                        HStack {
                                                            Image(systemName: item.isDirectory ? "folder.fill" : "doc.text")
                                                                .foregroundColor(item.isDirectory ? .blue : .gray)
                                                            Text(item.url.lastPathComponent)
                                                                .font(.system(.body, design: .monospaced))
                                                        }
                                                        if let count = item.itemCount {
                                                            Text("\(count) items")
                                                                .font(.caption)
                                                                .foregroundColor(.gray)
                                                        }
                                                    }
                                                    Spacer()
                                                }
                                                .padding()
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(8)
                                                .onTapGesture {
                                                    if item.isDirectory {
                                                        currentDirectory = item.url
                                                    } else if item.url.pathExtension == "md",
                                                              let content = vaultAccess.readMarkdownFile(at: item.url) {
                                                        selectedPreview = FilePreview(url: item.url, content: content)
                                                    }
                                                }
                                            }
                                        }
                                        .padding()
                                    }
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 20) {
                            Text("Select Obsidian Vault")
                                .font(.title)
                            Text("Navigate to iCloud Drive → Obsidian → iCloud_Vault")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Button("Browse") {
                                showVaultPicker = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
            }
            .ignoresSafeArea(.all, edges: .bottom)  // Only ignore bottom safe area
            .sheet(isPresented: $showVaultPicker) {
                DocumentPickerView { urls in
                    if let url = urls.first {
                        vaultAccess.saveVaultBookmark(url: url)
                        showVaultPicker = false  // Explicitly dismiss
                    }
                }
            }
            .sheet(item: $selectedPreview) { preview in
                NavigationView {
                    ScrollView {
                        Text(preview.content)
                            .padding()
                    }
                    .navigationTitle(preview.url.lastPathComponent)
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .id(shouldRefresh)
        )
    }
}

// Move URL Identifiable conformance to a private extension
private extension URL {
    var identifierForPage: String { absoluteString }
} 