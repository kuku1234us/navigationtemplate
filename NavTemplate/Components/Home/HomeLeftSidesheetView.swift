import SwiftUI

struct HomeLeftSidesheetView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("iOSWiz")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    // Settings action

                }) {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .foregroundColor(Color("Accent"))
                }
            }
            .padding()
            .background(Color("SideSheetBg"))
            
            // Content area
            Spacer()  // Takes up remaining space
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HomeLeftSidesheetView()
        .frame(width: SheetConstants.width)
        .background(Color("SideSheetBg"))
} 