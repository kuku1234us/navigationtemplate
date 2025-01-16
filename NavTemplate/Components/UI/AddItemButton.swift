// NavTemplate/Components/Tasks/AddItemButton.swift
import SwiftUI

struct AddItemButton: View {
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            Spacer()

            // Button to show sheet
            Button {
                onTap()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color("Accent"))
                    .clipShape(Circle())
                    .shadow(
                        color: Color.black,
                        radius: 10,
                        x: 0,
                        y: 5
                    )
                    .shadow(
                        color: Color("Accent").opacity(0.3),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, NavigationState.bottomMenuHeight + 10)
        }
    }
}
