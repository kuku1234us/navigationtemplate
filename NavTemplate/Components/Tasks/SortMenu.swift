import SwiftUI
import NavTemplateShared

struct SortMenuItem: View {
    let type: TaskSortOrderType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            UIImpactFeedbackGenerator.impact(.light)
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? type.selectedIcon : type.icon)
                    .frame(width: 24, alignment: .center)
                    .foregroundColor(isSelected ? Color("Accent") : Color("MyTertiary"))
                
                Text(type.label)
                    .foregroundColor(Color("MyTertiary"))
            }
            .frame(alignment: .leading)
            .padding(.horizontal, 12)
            .frame(height: 32)
        }
        .buttonStyle(.borderless)
    }
}

struct SortMenu: View {
    @StateObject private var sortOrder = TaskSortOrder.shared
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(TaskSortOrderType.allCases, id: \.self) { type in
                SortMenuItem(
                    type: type,
                    isSelected: sortOrder.currentOrder == type,
                    action: {
                        sortOrder.updateOrder(type)
                        onDismiss()
                    }
                )
            }
        }
        .padding()
        .background(Color("SideSheetBg").opacity(0.5))
        .withTransparentCardStyle()
    }
} 