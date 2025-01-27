// MonthView.swift

import SwiftUI

/// A simplified version of MonthView used only for height measurement
struct GhostMonthView: View {
    var body: some View {
        VStack(spacing: 0) {
            // The 6 rows representing the maximum height of a month view
            ForEach(0..<6, id: \.self) { _ in
                // Single cell with fixed height matching original MonthView
                Text("30")
                    .font(.system(size: 14))  // Match original font size
                    .frame(minHeight: 35)     // Match original cell height
                    .border(.cyan)
            }
        }
    }
}


