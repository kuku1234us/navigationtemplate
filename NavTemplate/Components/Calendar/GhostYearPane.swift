import SwiftUI

struct GhostYearPane: View {
    let reportMiniMonthRects: ([MiniMonthRect]) -> Void
    
    @State private var shortTitleRects: [CGRect] = Array(repeating: .zero, count: 12)
    @State private var longTitleRects: [CGRect] = Array(repeating: .zero, count: 12)
    @State private var viewRects: [CGRect] = Array(repeating: .zero, count: 12)
    @State private var hasReported = false
    
    private let calendar = Calendar.current
    
    private var months: [Date] {
        let year = calendar.component(.year, from: Date())
        return (1...12).compactMap { month in
            calendar.date(from: DateComponents(year: year, month: month, day: 1))
        }
    }
    
    private func checkAndReport() {
        // Check if all rects are collected
        if !shortTitleRects.contains(.zero) && 
           !longTitleRects.contains(.zero) && 
           !viewRects.contains(.zero) {
            // Create array of MiniMonthRect
            let rects = (0..<12).map { index in
                MiniMonthRect(
                    miniMonthShortTitleRect: shortTitleRects[index],
                    miniMonthLongTitleRect: longTitleRects[index],
                    miniMonthViewRect: viewRects[index]
                )
            }
            reportMiniMonthRects(rects)
            hasReported = true
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // First row: January - March
            HStack {
                ForEach(0..<3) { index in
                    MiniMonthCell(
                        monthDate: months[index],
                        onShortTitleRect: { rect in
                            shortTitleRects[index] = rect
                            checkAndReport()
                        },
                        onLongTitleRect: { rect in
                            longTitleRects[index] = rect
                            checkAndReport()
                        },
                        onViewRect: { rect in
                            viewRects[index] = rect
                            checkAndReport()
                        }
                    )
                    if index < 2 {
                        Spacer()
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            
            // Second row: April - June
            HStack {
                ForEach(3..<6) { index in
                    MiniMonthCell(
                        monthDate: months[index],
                        onShortTitleRect: { rect in
                            shortTitleRects[index] = rect
                            checkAndReport()
                        },
                        onLongTitleRect: { rect in
                            longTitleRects[index] = rect
                            checkAndReport()
                        },
                        onViewRect: { rect in
                            viewRects[index] = rect
                            checkAndReport()
                        }
                    )
                    if index < 5 {
                        Spacer()
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            
            // Third row: July - September
            HStack {
                ForEach(6..<9) { index in
                    MiniMonthCell(
                        monthDate: months[index],
                        onShortTitleRect: { rect in
                            shortTitleRects[index] = rect
                            checkAndReport()
                        },
                        onLongTitleRect: { rect in
                            longTitleRects[index] = rect
                            checkAndReport()
                        },
                        onViewRect: { rect in
                            viewRects[index] = rect
                            checkAndReport()
                        }
                    )
                    if index < 8 {
                        Spacer()
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            
            // Fourth row: October - December
            HStack {
                ForEach(9..<12) { index in
                    MiniMonthCell(
                        monthDate: months[index],
                        onShortTitleRect: { rect in
                            shortTitleRects[index] = rect
                            checkAndReport()
                        },
                        onLongTitleRect: { rect in
                            longTitleRects[index] = rect
                            checkAndReport()
                        },
                        onViewRect: { rect in
                            viewRects[index] = rect
                            checkAndReport()
                        }
                    )
                    if index < 11 {
                        Spacer()
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
    }

    private struct MiniMonthCell: View {
        let monthDate: Date
        let onShortTitleRect: (CGRect) -> Void
        let onLongTitleRect: (CGRect) -> Void
        let onViewRect: (CGRect) -> Void
        
        private let monthFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"  // Long month name
            return formatter
        }()
        
        private let shortMonthFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"  // Short month name
            return formatter
        }()
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                ZStack(alignment: .topLeading) {
                    // Short month name ("Jan")
                    Text(shortMonthFormatter.string(from: monthDate))
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(Color("MySecondary"))
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        onShortTitleRect(geo.frame(in: .global))
                                    }
                            }
                        )
                    
                    // Long month name ("January")
                    Text(monthFormatter.string(from: monthDate))
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(Color("MySecondary"))
                        .opacity(0)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        onLongTitleRect(geo.frame(in: .global))
                                    }
                            }
                        )
                }
                .padding(.horizontal, 0)
                
                MiniMonthView(monthDate: monthDate)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    onViewRect(geo.frame(in: .global))
                                }
                        }
                    )
            }
        }
    }
} 