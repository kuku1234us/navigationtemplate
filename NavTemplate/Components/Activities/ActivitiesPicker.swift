import SwiftUI
import NavTemplateShared

struct TimeAndActivityPickerDialog: View {
    let editingItem: ActivityItem  // Add reference to original item
    let onSave: (ActivityItem, ActivityType, Date) -> Void  // Pass original item in callback
    
    @State private var selectedActivity: Activity
    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    
    init(
        editingItem: ActivityItem,
        onSave: @escaping (ActivityItem, ActivityType, Date) -> Void
    ) {
        self.editingItem = editingItem
        self.onSave = onSave
        
        let calendar = Calendar.current
        _selectedActivity = State(initialValue: Activity(type: editingItem.activityType))
        _selectedHour = State(initialValue: calendar.component(.hour, from: editingItem.activityTime))
        _selectedMinute = State(initialValue: calendar.component(.minute, from: editingItem.activityTime))
    }
    
    private func createSelectedDate() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: editingItem.activityTime)
        components.hour = selectedHour
        components.minute = selectedMinute
        return calendar.date(from: components) ?? editingItem.activityTime
    }
    
    private let activities: [Activity] = ActivityType.allCases.map { Activity(type: $0) }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Activity Picker
                ActivityPicker(selection: $selectedActivity, activities: activities)
                    .frame(height: 150)
                    .clipped()

                // Hour Picker with Looping
                HourPicker(selection: $selectedHour)
                    .frame(height: 150)
                    .clipped()

                // Minute Picker with Looping
                MinutePicker(selection: $selectedMinute)
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
            
            Button(action: {
                let selectedDate = createSelectedDate()
                onSave(editingItem, selectedActivity.type, selectedDate)
            })
            {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("ButtonBg").opacity(0.25))
                        .frame(maxWidth: 300)
                        .frame(height: 44)
                        .backgroundBlur(radius: 10, opaque: true)
                        .innerShadow(shape: RoundedRectangle(cornerRadius: 12), color: Color.bottomSheetBorderMiddle , lineWidth: 1, offsetX: 0, offsetY: 1, blur: 0, blendMode: .overlay, opacity: 1)
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

private struct ActivityPicker: View {
    @Binding var selection: Activity
    let activities: [Activity]
    
    var body: some View {
        PickerViewWithoutIndicator(id: "Activity", selection: $selection) {
            ForEach(activities, id: \.self) { activity in
                HStack(spacing: 8) {
                    Image(systemName: selection == activity ? activity.filledIcon : activity.unfilledIcon)
                        .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                        .foregroundColor(selection == activity ? .accentColor : .gray)                        
                    Text(activity.name)
                }
                .frame(width: 120, alignment: .center)
                .tag(activity)
            }
        }
    }
}

private struct HourPicker: View {
    @Binding var selection: Int
    private let hourRange = Array(0..<24)
    
    var body: some View {
        PickerViewWithoutIndicator(id: "Hour", selection: $selection) {
            ForEach(hourRange, id: \.self) { hour in
                Text(String(format: "%02d", hour))
                    .frame(width: 35, alignment: .center)
                    .tag(hour)
            }
        }
    }
}

private struct MinutePicker: View {
    @Binding var selection: Int
    private let minuteRange = Array(0..<60)
    
    var body: some View {
        PickerViewWithoutIndicator(id: "Minute", selection: $selection) {
            ForEach(minuteRange, id: \.self) { minute in
                Text(String(format: "%02d", minute))
                    .frame(width: 35, alignment: .center)
                    .tag(minute)
            }
        }
    }
}

// Custom InfinitePicker
struct InfinitePicker<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    @Binding var selection: Data.Element
    let content: (Data.Element) -> Content
    @State private var forceUpdate = false  // Add state to force rerender
    
    // Convert to Array for easier indexing
    private var dataArray: [Data.Element] {
        Array(data)
    }
    
    // Create extended range for visual continuity
    private var extendedIndices: Range<Int> {
        let count = dataArray.count
        return -count..<(count * 2)  // Show one set before and one after
    }
    
    private var selectionIndex: Binding<Int> {
        Binding(
            get: {
                dataArray.firstIndex(of: selection) ?? 0
            },
            set: { newValue in
                let count = dataArray.count
                // Wrap the index to valid range
                let wrappedIndex = ((newValue % count) + count) % count
                selection = dataArray[wrappedIndex]
            }
        )
    }
    
    var body: some View {
        PickerViewWithoutIndicator(id: "InfinitePicker", selection: selectionIndex) {
            ForEach(extendedIndices, id: \.self) { index in
                let wrappedIndex = ((index % dataArray.count) + dataArray.count) % dataArray.count
                content(dataArray[wrappedIndex])
                    .tag(index)
            }
        }
        .id(forceUpdate)  // Force view recreation when this changes
        .onAppear {
            // Force initial render
            DispatchQueue.main.async {
                forceUpdate.toggle()
            }
        }
        .onChange(of: selectionIndex.wrappedValue) { oldValue, newValue in
            withAnimation {
                let count = dataArray.count
                let wrappedIndex = ((newValue % count) + count) % count
                if wrappedIndex != newValue {
                    selectionIndex.wrappedValue = wrappedIndex
                }
                forceUpdate.toggle()
            }
        }
    }
}

// Preview
// struct TimeAndActivityPickerDialog_Previews: PreviewProvider {
//     static var previews: some View {
//         TimeAndActivityPickerDialog(
//             initialActivity: .sleep,
//             initialTime: Date(),
//             onSave: { _, _ in },
//             onCancel: {}
//         )
//         .preferredColorScheme(.dark)
//     }
// }

struct PickerViewWithoutIndicator<Content: View, Selection: Hashable>: View {
    @Binding var selection: Selection
    @ViewBuilder var content: Content
    @State private var isHidden: Bool = false
    let id: String  // Add identifier
    
    init(id: String = "Unknown", selection: Binding<Selection>, @ViewBuilder content: () -> Content) {
        self._selection = selection
        self.content = content()
        self.id = id
    }
    
    var body: some View {
        Picker("", selection: $selection) {
            if !isHidden {
                RemovePickerIndicator(id: id) {
                    isHidden = true
                }
            }
            content
        }
        .pickerStyle(.wheel)
    }
}

struct RemovePickerIndicator: UIViewRepresentable {
    var result: () ->()
    let id: String  // Add identifier
    
    init(id: String = UUID().uuidString, result: @escaping () -> ()) {
        self.id = id
        self.result = result
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        DispatchQueue.main.async {
            if let pickerView = view.pickerView {
                if pickerView.subviews.count >= 2 {
                    pickerView.subviews[1].backgroundColor = .clear
                } 
                result()
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {

    }
}

extension UIView {
    var pickerView: UIPickerView? {
        if let view = superview as? UIPickerView {
            return view
        }
        return superview?.pickerView
    }
}
