import SwiftUI

struct ActivitiesMenu: View {
    let onSelect: (ActivityType) -> Void
    @Binding var consciousState: ActivityType
    @State private var selectedActivity: ActivityType?
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(ActivityType.allCases, id: \.self) { activity in
                CircleButton(
                    icon: selectedActivity == activity ? activity.filledIcon : activity.unfilledIcon,
                    iconColor: selectedActivity == activity ? Color("Accent") : Color("MyTertiary"),
                    buttonColor: selectedActivity == activity ? Color("ButtonBg") : Color("SideSheetBg"),
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedActivity = activity
                            onSelect(activity)
                        }
                    }
                )
                .disabled((consciousState == .wake && activity == .wake) ||
                         (consciousState == .sleep && activity == .sleep))
                .opacity((consciousState == .wake && activity == .wake) ||
                        (consciousState == .sleep && activity == .sleep) ? 0.5 : 1.0)
            }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: 100)
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        ActivitiesMenu(
            onSelect: { activity in
                print("Selected: \(activity.rawValue)")
            },
            consciousState: .constant(.wake)
        )
    }
} 