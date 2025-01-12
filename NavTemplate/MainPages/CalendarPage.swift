import SwiftUI
import NavTemplateShared

struct CalendarPage: Page {
    var navigationManager: NavigationManager?
    
    // Required by Page protocol
    var widgets: [AnyWidget] {
        return []  // No widgets for now
    }
    
    func makeMainContent() -> AnyView {
        AnyView(
            ZStack {
                // Background
                Image("batmanDim")
                    .resizable()
                    .ignoresSafeArea()
                    .overlay(.black.opacity(0.5))
                
                VStack {
                    Text("Calendar")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .foregroundColor(Color("PageTitle"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        )
    }
} 