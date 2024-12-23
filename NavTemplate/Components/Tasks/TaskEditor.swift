// NavTemplate/Components/Tasks/TaskEditor.swift

import SwiftUI
import NavTemplateShared

struct TaskEditor: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPriority: TaskPriority = .normal
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 16) {
            Rectangle()
                .fill(Color("SideSheetBg").opacity(0.2))
                .frame(height: 10)
                .padding(.horizontal, 12)
                .border(.blue, width: 1)

            TextEditor(text: $text)
                .font(.system(size: 16))
                .foregroundColor(Color("MyPrimary"))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .border(.red, width: 1)
                .focused($isFocused)
                .frame(height: 80)
            
            Menu {
                ForEach([TaskPriority.urgent, .high, .normal, .low], id: \.self) { priority in
                    Button {
                        selectedPriority = priority
                    } label: {
                        HStack {
                            Circle()
                                .fill(priority.color)
                                .frame(width: 8, height: 8)
                            Text(priority.rawValue)
                            if priority == selectedPriority {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Circle()
                        .fill(selectedPriority.color)
                        .frame(width: 8, height: 8)
                    Text(selectedPriority.rawValue)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                }
                .foregroundColor(Color("MySecondary"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color("SideSheetBg").opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 16)
        .withTransparentRoundedTopStyle()
        .offset(y: -keyboardHeight)
        .animation(.easeOut(duration: 0.16), value: keyboardHeight)
        .onAppear {
            isFocused = true
            setupKeyboardObservers()
        }
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            keyboardHeight = keyboardFrame?.height ?? 0
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            keyboardHeight = 0
        }
    }
}