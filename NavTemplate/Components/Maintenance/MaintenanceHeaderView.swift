import SwiftUI

struct MaintenanceHeaderView: View {
    @Binding var showClearConfirmation: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Maintenance")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(Color("PageTitle"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: {
                    showClearConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(Color("MyTertiary"))
                }
            }
        }
        .withSafeAreaTop()
        .padding()
        .backgroundBlur(radius: 10, opaque: true)
        .background(
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0.0,0.0], [0.5,0.0], [1.0,0.0],
                    [0.0,0.5], [0.5,0.5], [1.0,0.5],
                    [0.0,1.0], [0.5,1.0], [1.0,1.0]
                ],
                colors: [
                    Color("Background"),Color("Background"),.black,
                    .blue,Color("Background"),Color("Background"),
                    .blue,.blue,Color("Background"),                    
                ]
            )
            .opacity(0.1)
        )
    }
} 