import SwiftUI
import NavTemplateShared

struct iCloudPage: Page {
    var navigationManager: NavigationManager?
    var widgets: [AnyWidget] { [] }
    
    @State private var showingFilePicker = false
    @State private var vaultPath: String = ""
    @State private var errorMessage: String?
    
    func makeMainContent() -> AnyView {
        AnyView(
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
                            print("Selected vault successfully: \(url.path)")
                            
                            guard url.startAccessingSecurityScopedResource() else {
                                errorMessage = "Failed to access the selected location"
                                return
                            }
                            
                            ObsidianVaultAccess.shared.saveVaultURL(url)
                            url.stopAccessingSecurityScopedResource()
                            
                            vaultPath = url.path
                            errorMessage = nil
                        }
                    case .failure(let error):
                        print("Error selecting vault: \(error)")
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .padding()
        )
    }
} 