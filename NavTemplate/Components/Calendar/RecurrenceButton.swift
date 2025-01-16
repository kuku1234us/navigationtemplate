import SwiftUI

struct RecurrenceButton: View {
    @Binding var selectedRecurrence: String?
    
    var body: some View {
        Menu {
            Button {
                selectedRecurrence = nil
            } label: {
                HStack {
                    Image(systemName: "circle.slash")
                    Text("None")
                    if selectedRecurrence == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button {
                selectedRecurrence = "D"
            } label: {
                HStack {
                    Image(systemName: "d.circle.fill")
                    Text("Daily")
                    if selectedRecurrence == "D" {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button {
                selectedRecurrence = "W"
            } label: {
                HStack {
                    Image(systemName: "w.circle.fill")
                    Text("Weekly")
                    if selectedRecurrence == "W" {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button {
                selectedRecurrence = "M"
            } label: {
                HStack {
                    Image(systemName: "m.circle.fill")
                    Text("Monthly")
                    if selectedRecurrence == "M" {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button {
                selectedRecurrence = "Y"
            } label: {
                HStack {
                    Image(systemName: "a.circle.fill")
                    Text("Annually")
                    if selectedRecurrence == "Y" {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            Image(systemName: selectedRecurrence == nil ? "arrow.trianglehead.2.clockwise.rotate.90.circle" :
                            selectedRecurrence == "D" ? "d.circle.fill" :
                            selectedRecurrence == "W" ? "w.circle.fill" :
                            selectedRecurrence == "M" ? "m.circle.fill" :
                            selectedRecurrence == "Y" ? "a.circle.fill" : "circle.slash")
                .foregroundColor(selectedRecurrence == nil ? Color("MyTertiary") : Color("Accent"))
                .font(.system(size: 24))
                .background(
                    Circle()
                        .fill(Color("SideSheetBg"))
                        .frame(width: 22, height: 22)
                )
        }
    }
} 