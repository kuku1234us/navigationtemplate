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
            HStack {
                Image(systemName: isSelected ? type.selectedIcon : type.icon)
                    .foregroundColor(isSelected ? Color("Accent") : Color("MyTertiary"))
                Text(type.label)
                    .foregroundColor(Color("MyTertiary"))
            }
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
        VStack(spacing: 4) {
            ForEach([TaskSortOrderType.taskCreationDesc, .projModifiedDesc], id: \.self) { type in
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