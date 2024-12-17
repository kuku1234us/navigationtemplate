import SwiftUI
import NavTemplateShared

struct TimeIndicatorsView: View {
    let consciousState: ActivityType
    let consciousTimeDisplay: String
    let mealTimeDisplay: String
    
    var body: some View {
        VStack(spacing: 5) {
            // Conscious state indicator
            HStack(spacing: 4) {
                Image(systemName: consciousState == .sleep ? "moon.zzz.fill" : "cloud.sun.fill")
                    .foregroundColor(Color("MySecondary"))
                Text(consciousTimeDisplay)
                    .foregroundColor(Color("MyTertiary"))
                    .font(.system(size: 14))
            }
            
            // Meal time indicator
            HStack(spacing: 4) {
                Image(systemName: "fork.knife.circle.fill")
                    .foregroundColor(Color("MySecondary"))
                Text(mealTimeDisplay)
                    .foregroundColor(Color("MyTertiary"))
                    .font(.system(size: 14))
            }
        }
    }
} 