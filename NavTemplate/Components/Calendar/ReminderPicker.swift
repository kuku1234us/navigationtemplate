import SwiftUI

struct ReminderPickerDialog: View {
    let onSave: (Int) -> Void  // Callback with total minutes
    
    @State private var selectedWeeks: Int = 0
    @State private var selectedDays: Int = 0
    @State private var selectedHours: Int = 0
    @State private var selectedMinutes: Int = 0
    
    private let weeksRange = Array(0...52)
    private let daysRange = Array(0...30)
    private let hoursRange = Array(0...24)
    private let minutesRange = Array(0...60)
    
    private func calculateTotalMinutes() -> Int {
        let weekMinutes = selectedWeeks * 7 * 24 * 60
        let dayMinutes = selectedDays * 24 * 60
        let hourMinutes = selectedHours * 60
        return weekMinutes + dayMinutes + hourMinutes + selectedMinutes
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Weeks Picker
                WeeksPicker(selection: $selectedWeeks)
                    .frame(height: 150)
                    .clipped()
                
                // Days Picker
                DaysPicker(selection: $selectedDays)
                    .frame(height: 150)
                    .clipped()
                
                // Hours Picker
                HoursPicker(selection: $selectedHours)
                    .frame(height: 150)
                    .clipped()
                
                // Minutes Picker
                MinutesPicker(selection: $selectedMinutes)
                    .frame(height: 150)
                    .clipped()
            }
            .offset(x: 25)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                    .frame(height: 35)
            }
            .padding()
            .cornerRadius(12)
            .shadow(radius: 10)
            .frame(maxWidth: 350)
            
            // Save Button
            Button(action: {
                onSave(calculateTotalMinutes())
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("ButtonBg").opacity(0.25))
                        .frame(maxWidth: 300)
                        .frame(height: 44)
                        .backgroundBlur(radius: 10, opaque: true)
                        .innerShadow(
                            shape: RoundedRectangle(cornerRadius: 12),
                            color: Color.bottomSheetBorderMiddle,
                            lineWidth: 1,
                            offsetX: 0,
                            offsetY: 1,
                            blur: 0,
                            blendMode: .overlay,
                            opacity: 1
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color("Accent"))
                }
            }
            .padding(.bottom)
        }
        .withTransparentCardStyle()
    }
}

private struct WeeksPicker: View {
    @Binding var selection: Int
    private let weeksRange = Array(0...52)
    
    var body: some View {
        PickerViewWithoutIndicator(id: "Weeks", selection: $selection) {
            ForEach(weeksRange, id: \.self) { weeks in
                Text("\(weeks)w")
                    .frame(width: 50, alignment: .center)
                    .tag(weeks)
            }
        }
    }
}

private struct DaysPicker: View {
    @Binding var selection: Int
    private let daysRange = Array(0...30)
    
    var body: some View {
        PickerViewWithoutIndicator(id: "Days", selection: $selection) {
            ForEach(daysRange, id: \.self) { days in
                Text("\(days)d")
                    .frame(width: 50, alignment: .center)
                    .tag(days)
            }
        }
    }
}

private struct HoursPicker: View {
    @Binding var selection: Int
    private let hoursRange = Array(0...24)
    
    var body: some View {
        PickerViewWithoutIndicator(id: "Hours", selection: $selection) {
            ForEach(hoursRange, id: \.self) { hours in
                Text("\(hours)h")
                    .frame(width: 50, alignment: .center)
                    .tag(hours)
            }
        }
    }
}

private struct MinutesPicker: View {
    @Binding var selection: Int
    private let minutesRange = Array(0...60)
    
    var body: some View {
        PickerViewWithoutIndicator(id: "Minutes", selection: $selection) {
            ForEach(minutesRange, id: \.self) { minutes in
                Text("\(minutes)m")
                    .frame(width: 50, alignment: .center)
                    .tag(minutes)
            }
        }
    }
} 