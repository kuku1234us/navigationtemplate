import SwiftUI

struct TestPage: View {
    @State private var showBottomSheet = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Button to show sheet
            Button {
                showBottomSheet = true
            } label: {
                Text("Show Bottom Sheet")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color("Accent"))
                    .cornerRadius(10)
            }
            
            // Bottom sheet
            if showBottomSheet {
                BottomSheet(isPresented: $showBottomSheet) {
                    TestContent()
                }
                .background(
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showBottomSheet = false
                        }
                )
            }
        }
    }
}

