import SwiftUI
import AudioToolbox
import NavTemplateShared

struct ReminderPicker: View {
    let onSave: (ReminderType) -> Void
    @Binding var isPresented: Bool  // Add binding to control dismissal
    
    @State private var selectedWeeks: Int = 0
    @State private var selectedDays: Int = 0
    @State private var selectedHours: Int = 0
    @State private var selectedMinutes: Int = 0
    @State private var selectedSound: String = DefaultNotificationSound
    
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
    
    // Add function to play selected sound
    private func playSound() {
        if let soundURL = Bundle(for: NotificationModel.self).url(forResource: selectedSound, withExtension: "aiff") {
            var soundID: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &soundID)
            AudioServicesPlaySystemSound(soundID)
            
            // Clean up after playing
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                AudioServicesDisposeSystemSoundID(soundID)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Sound Picker
                SoundPicker(selection: $selectedSound)
                    .frame(height: 150)
                    .clipped()
                
                // Weeks Picker
                WeeksPicker(selection: $selectedWeeks)
                    .frame(width: 50, height: 150)
                    .clipped()
                
                // Days Picker
                DaysPicker(selection: $selectedDays)
                    .frame(width: 50, height: 150)
                    .clipped()
                
                // Hours Picker
                HoursPicker(selection: $selectedHours)
                    .frame(width: 50, height: 150)
                    .clipped()
                
                // Minutes Picker
                MinutesPicker(selection: $selectedMinutes)
                    .frame(width: 50, height: 150)
                    .clipped()
            }
            .offset(x: 0)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                    .frame(height: 30)
            }
            .padding()
            .cornerRadius(12)
            .shadow(radius: 10)
            .frame(maxWidth: 430)  // Increased to accommodate sound picker
            
            // Three Button Row
            HStack(spacing: 20) {
                // Play Sound Button
                Button(action: playSound) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("ButtonBg").opacity(0.25))
                            .frame(width: 44, height: 44)
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
                        
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color("Accent"))
                    }
                }
                
                // Save Button
                Button(action: {
                    let reminder = ReminderType(minutes: calculateTotalMinutes(), sound: selectedSound)
                    onSave(reminder)
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("ButtonBg").opacity(0.25))
                            .frame(width: 44, height: 44)
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
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color("Accent"))
                    }
                }
                
                // Cancel Button
                Button(action: { isPresented = false }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("ButtonBg").opacity(0.25))
                            .frame(width: 44, height: 44)
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
                        
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color("MyTertiary"))
                    }
                }
            }
            .padding(.bottom)
        }
        .withTransparentCardStyle()
        .onAppear {
            // Reset all values when picker appears
            selectedWeeks = 0
            selectedDays = 0
            selectedHours = 0
            selectedMinutes = 0
            selectedSound = DefaultNotificationSound
        }
    }
}

private struct WeeksPicker: View {
    @Binding var selection: Int
    private let weeksRange = Array(0...52)
    
    var body: some View {
        PickerViewWithoutIndicator(id: "Weeks", selection: $selection) {
            ForEach(weeksRange, id: \.self) { weeks in
                Text("\(weeks)w")
                    .font(.system(size: 14))
                    .frame(width: 30, alignment: .center)
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
                    .font(.system(size: 14))
                    .frame(width: 30, alignment: .center)
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
                    .font(.system(size: 14))
                    .frame(width: 30, alignment: .center)
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
                    .font(.system(size: 14))
                    .frame(width: 30, alignment: .center)
                    .tag(minutes)
            }
        }
    }
}

private struct SoundPicker: View {
    @Binding var selection: String
    private let sounds = [
        "Game",
        "Flute",
        "Keyboard",
        "ChordWhistle",
        "Reality",
        "Elevator3",
        "Harp",
        "Elevator",
        "Dingding"
    ]
    
    var body: some View {
        PickerViewWithoutIndicator(id: "Sound", selection: $selection) {
            ForEach(sounds, id: \.self) { sound in
                Text(sound)
                    .font(.system(size: 14))
                    .frame(width: 80, alignment: .center)
                    .tag(sound)
            }
        }
    }
} 