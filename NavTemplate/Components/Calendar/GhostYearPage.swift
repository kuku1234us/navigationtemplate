import SwiftUI

struct GhostYearPage: View {
    let reportMiniMonthRects: ([MiniMonthRect]) -> Void
    @Binding var ghostYearPaneRect: CGRect
    
    var body: some View {
        VStack(spacing: 0) {
            GhostYearHeader()
                .border(.red)
            
            GhostYearPane(reportMiniMonthRects: reportMiniMonthRects)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                ghostYearPaneRect = geo.frame(in: .global)
                            }
                    }
                )
                .border(.blue)
            
            Spacer()
        }
    }
}