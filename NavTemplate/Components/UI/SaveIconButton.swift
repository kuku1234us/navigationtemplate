import SwiftUI

struct SaveIconButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(Color("Accent"))
                .background(
                    Circle()
                        .fill(Color("SideSheetBg"))
                        .frame(width: 22, height: 22)
                )
        }
    }
} 