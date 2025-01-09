import SwiftUI
import NavTemplateShared

struct ActivitiesPageHeader: View {
    let navigationManager: NavigationManager?
    @Binding var consciousState: ActivityType
    let lastConsciousTime: Date?
    let lastMealTime: Date?
    
    // Add timer to update display
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    private func formatTimeSince(_ date: Date?) -> String {
        guard let date = date else { return "00:00" }
        let interval = currentTime.timeIntervalSince(date)
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Activities")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(Color("PageTitle"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            
            // Time indicators
            HStack(spacing: 20) {
                // Conscious state indicator
                HStack(spacing: 8) {
                    Image(systemName: consciousState == .sleep ? "moon.zzz.fill" : "cloud.sun.fill")
                        .foregroundColor(Color("MySecondary"))
                    Text(formatTimeSince(lastConsciousTime))
                        .foregroundColor(Color("MyTertiary"))
                }
                
                // Meal time indicator
                HStack(spacing: 8) {
                    Image(systemName: "fork.knife.circle.fill")
                        .foregroundColor(Color("MySecondary"))
                    Text(formatTimeSince(lastMealTime))
                        .foregroundColor(Color("MyTertiary"))
                }
                Spacer()
            }
            .padding(.top, 4)
            .padding(.horizontal)
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
                    .white,Color("Background"),Color("Background"),
                    .white,.white,Color("Background"),                    
                ]
            )
            .blendMode(.overlay)
        )
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}
