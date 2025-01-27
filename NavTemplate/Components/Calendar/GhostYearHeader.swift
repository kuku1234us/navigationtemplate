import SwiftUI
import NavTemplateShared

struct GhostYearHeader: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Text field
                Text("2025")
                    .font(.largeTitle)
                    .fontWeight(.black)
                Spacer()
            }
            // .border(.purple)
            .padding(.horizontal, 12)

            Rectangle()
                .frame(height: CalendarHeaderView.heightHolderMinHeight)
                .foregroundColor(.clear)
                // .border(.purple)
        }
        .withSafeAreaTop()
        .padding(.top)
        .opacity(1)
        // .padding(.bottom, 5)
        // .border(Color("Accent"), width: 1)
    }
} 