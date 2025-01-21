import SwiftUI
import NavTemplateShared

struct iCloudPage: View {
    @State private var showingFilePicker = false
    @State private var vaultPath: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select Obsidian Vault")
                .font(.title)
            
            if let url = ObsidianVaultAccess.shared.vaultURL {
                Text("Current vault: \(url.lastPathComponent)")
                    .foregroundColor(.gray)
                
                Text(url.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
            
            Button("Choose Vault Location") {
                showingFilePicker = true
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        print("Selected vault URL: \(url.path)")
                        
                        // Start accessing the URL before any operations
                        guard url.startAccessingSecurityScopedResource() else {
                            errorMessage = "Failed to access the selected location"
                            return
                        }
                        
                        // Create a bookmark
                        do {
                            let bookmarkData = try url.bookmarkData(
                                options: .minimalBookmark,
                                includingResourceValuesForKeys: nil,
                                relativeTo: nil
                            )
                            
                            // Verify the bookmark works immediately
                            var isStale = false
                            let verifiedURL = try URL(
                                resolvingBookmarkData: bookmarkData,
                                options: [],
                                relativeTo: nil,
                                bookmarkDataIsStale: &isStale
                            )
                            
                            if isStale {
                                throw NSError(domain: "com.app.error", code: -1, 
                                            userInfo: [NSLocalizedDescriptionKey: "Bookmark became stale immediately"])
                            }
                            
                            // Save bookmark data first
                            ObsidianVaultAccess.shared.saveVaultBookmark(bookmarkData)
                            
                            // Then save URL
                            ObsidianVaultAccess.shared.saveVaultURL(verifiedURL)
                            
                            vaultPath = verifiedURL.path
                            errorMessage = nil
                            
                        } catch {
                            print("Error creating/verifying bookmark: \(error)")
                            errorMessage = "Failed to secure access: \(error.localizedDescription)"
                        }
                        
                        // Stop accessing at the end
                        url.stopAccessingSecurityScopedResource()
                    }
                case .failure(let error):
                    print("Error selecting vault: \(error)")
                    errorMessage = error.localizedDescription
                }
            }
            
            // Add a button to clear current bookmark if needed
            if ObsidianVaultAccess.shared.vaultURL != nil {
                Button("Clear Current Vault Access", role: .destructive) {
                    ObsidianVaultAccess.shared.clearVaultAccess()
                    errorMessage = nil
                }
                .padding(.top)
            }
        }
        .padding()
    }
} 