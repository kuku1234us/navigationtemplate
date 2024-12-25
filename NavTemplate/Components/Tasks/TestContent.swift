// NavTemplate/Components/Tasks/TestContent.swift

import SwiftUI

struct TestContent: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("Test Content")
                .font(.headline)
                .padding()
            
            Divider()
            
            List(1...10, id: \.self) { number in
                Text("Item \(number)")
            }
            .listStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Background"))
        .edgesIgnoringSafeArea(.vertical)
    }
}

