import SwiftUI

struct TestPage: View {
    @State private var userDefaultsKeys: [String] = []
    
    private func deleteKey(_ key: String) {
        if let defaults = UserDefaults(suiteName: "group.us.kothreat.NavTemplate") {
            defaults.removeObject(forKey: key)
            // Refresh the keys list
            userDefaultsKeys = Array(defaults.dictionaryRepresentation().keys).sorted()
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("UserDefaults Keys")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(userDefaultsKeys, id: \.self) { key in
                    HStack {
                        Button(action: {
                            deleteKey(key)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.footnote)
                        }
                        .buttonStyle(.plain)
                        
                        Text(key)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(Color("MySecondary"))
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .padding(.bottom, 60)
        }
        .onAppear {
            // Get all keys from app group UserDefaults
            if let defaults = UserDefaults(suiteName: "group.us.kothreat.NavTemplate") {
                userDefaultsKeys = Array(defaults.dictionaryRepresentation().keys).sorted()
            }
        }
    }
}

