// NavTemplate/Components/Tasks/AddTaskButton.swift
import SwiftUI

struct AddTaskButton: View {
    @State private var showTaskEditor = false
    @State private var taskText = ""
    
    var body: some View {
        VStack {
            Spacer()
            Button {
                taskText = ""  // Reset text
                showTaskEditor = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color("Accent"))
                    .clipShape(Circle())
                    .shadow(color: Color("Accent").opacity(0.4), radius: 4, x: 0, y: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, NavigationState.bottomMenuHeight)
        }
        .sheet(isPresented: $showTaskEditor) {
            TaskEditor(text: $taskText)
                .presentationDetents([.height(150),.height(250)])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
                .presentationCornerRadius(20)
                .presentationBackground(.clear)
                .ignoresSafeArea()
        }

    }
}