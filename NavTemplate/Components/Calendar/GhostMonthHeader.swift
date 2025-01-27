import SwiftUI
import NavTemplateShared

struct GhostMonthHeader: View {
    let curDate: Date
    let reportMonthTitleRects: ([CGRect], [CGRect]) -> Void
    @Binding var ghostWeekdayRect: CGRect

    @State private var searchText = ""
    @State private var shortTitleRects: [CGRect] = Array(repeating: .zero, count: 12)
    @State private var longTitleRects: [CGRect] = Array(repeating: .zero, count: 12)
    @State private var hasReported = false
    
    private let calendar = Calendar.current
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"  // Long format ("January")
        return formatter
    }()
    
    private let shortMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"   // Short format ("Jan")
        return formatter
    }()
    
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
           !hasReported {
            reportMonthTitleRects(shortTitleRects, longTitleRects)
            hasReported = true
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Text field
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.vertical, 5)
            .border(.purple)
            .padding(.horizontal, 12)

            // Middle row of header
            HStack {
                ZStack(alignment: .topLeading) {
                    // Render all months (both short and long) at the same position
                    ForEach(months.indices, id: \.self) { index in
                        // Short month name ("Jan")
                        Text(shortMonthFormatter.string(from: months[index]))
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .foregroundColor(.green)
                            .opacity(0.5)  // Make visible for debugging
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .onAppear {
                                            shortTitleRects[index] = geo.frame(in: .global)
                                            checkAndReport()
                                        }
                                }
                            )
                        
                        // Long month name ("January")
                        Text(monthFormatter.string(from: months[index]))
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .foregroundColor(.red)
                            .opacity(0.5)  // Make visible for debugging
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .onAppear {
                                            longTitleRects[index] = geo.frame(in: .global)
                                            checkAndReport()
                                        }
                                }
                            )
                    }
                }
                .offset(x: 0)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            
            // Bottom row - weekday letters
            HStack(spacing: 0) {
                Text("S")
                    .font(.footnote)
                    .foregroundColor(Color("MyTertiary"))
                Spacer()
            }
            .padding(.top, 4)
            .border(.purple)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            ghostWeekdayRect = geo.frame(in: .global)
                        }
                }
            )
        }
        .withSafeAreaTop()
        .padding(.top)
        .padding(.bottom, 5)
        .border(Color("Accent"), width: 1)
    }
} 