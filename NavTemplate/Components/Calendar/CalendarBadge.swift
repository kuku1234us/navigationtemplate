import SwiftUI

public struct CalendarBadge: View {
    let date: Date
    
    public init(date: Date) {
        self.date = date
    }
    
    private var dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter
    }()
    
    public var body: some View {
        ZStack {
            // Calendar SVG background
            Image("CalendarSVG")
                .resizable()
                .renderingMode(.template)
                .frame(width: 35, height: 35)
                .foregroundColor(Color("MyTertiary").opacity(0.5))
            
            // Day number
            Text(dayFormatter.string(from: date))
                .font(.system(size: 12, weight: .black))
                .foregroundColor(Color("MySecondary"))
                .offset(y: 5) // Adjust if needed to center within calendar icon
        }
    }
} 