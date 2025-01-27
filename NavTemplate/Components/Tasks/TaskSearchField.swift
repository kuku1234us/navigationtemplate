import SwiftUI

struct TaskSearchField: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            // Search icon or clear button
            Button(action: {
                if !text.isEmpty {
                    text = ""
                }
            }) {
                Image(systemName: text.isEmpty ? "magnifyingglass" : "x.circle.fill")
                    .foregroundColor(Color("MyTertiary").opacity(0.5))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            
            // Text field
            TextField("Search...", text: $text)
                .textFieldStyle(.plain)
                .foregroundColor(Color("MySecondary"))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0.0,0.0], [0.5,0.0], [1.0,0.0],
                    [0.0,0.5], [0.5,0.5], [1.0,0.5],
                    [0.0,1.0], [0.5,1.0], [1.0,1.0]
                ],
                colors: [
                    .white,.white,Color("Background"),                    
                    .white,Color("Background"),Color("Background"),
                    Color("Background"),Color("Background"),.black,
                ]
            )
            .blendMode(.overlay)
            .opacity(0.7)
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color("MyTertiary").opacity(0.2), lineWidth: 1)
        )
    }
} 