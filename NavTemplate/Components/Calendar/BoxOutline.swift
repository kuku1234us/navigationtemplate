import SwiftUI

struct BoxOutline: View {
    let miniMonthRects: [MiniMonthRect]
    
    var body: some View {
        ZStack {
            // Draw all title rects
            // ForEach(Array(miniMonthRects.enumerated()), id: \.offset) { index, rect in
            //     // Title rect
            //     Rectangle()
            //         .stroke(Color.red, lineWidth: 1)
            //         .frame(
            //             width: rect.miniMonthTitleRect.width,
            //             height: rect.miniMonthTitleRect.height
            //         )
            //         .position(
            //             x: rect.miniMonthTitleRect.midX,
            //             y: rect.miniMonthTitleRect.midY
            //         )
                
            //     // View rect
            //     Rectangle()
            //         .stroke(Color.blue, lineWidth: 1)
            //         .frame(
            //             width: rect.miniMonthViewRect.width,
            //             height: rect.miniMonthViewRect.height
            //         )
            //         .position(
            //             x: rect.miniMonthViewRect.midX,
            //             y: rect.miniMonthViewRect.midY
            //         )
                
            //     // Add month number label for debugging
            //     Text("\(index + 1)")
            //         .font(.caption)
            //         .foregroundColor(.yellow)
            //         .position(
            //             x: rect.miniMonthTitleRect.minX - 10,
            //             y: rect.miniMonthTitleRect.midY
            //         )
            // }
        }
        .ignoresSafeArea()
    }
} 