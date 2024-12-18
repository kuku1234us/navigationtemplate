// DailyPage.swift

import SwiftUI

struct DailyPage: Page {
    var navigationManager: NavigationManager?
    var widgets: [AnyWidget] { [] }  // Empty, not using widgets
    let date: Date
    
    init(date: Date, navigationManager: NavigationManager?) {
        self.date = date
        self.navigationManager = navigationManager
    }
    
    func makeMainContent() -> AnyView {
        AnyView(
            ZStack {
                VStack {
                    Text("Daily Page")
                        .font(.largeTitle)
                    Text("Date: \(date.formatted(date: .long, time: .omitted))")
                    Button("Go Back") {
                        navigationManager?.navigateBack()
                    }
                }
                
                FrostedGlassCard(
                    title: "Daily Summary",
                    description: "Today is \(date.formatted(date: .complete, time: .omitted))"
                )
                .frame(width: 300, height: 200)
                .offset(y: -85)  // Changed from -100 to -90 to move down 10px
            }
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        if value.translation.width > 0 {
                            print("Left drag handler: Claiming left-to-right drag")
                        }
                    }
                    .exclusively(before: 
                        TapGesture()
                            .onEnded {
                                print("Tap handler: Claiming tap")
                            }
                    )
            )
        )
    }
}

