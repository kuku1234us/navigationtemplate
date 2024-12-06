//
//  ContentView.swift
//  NavTemplate
//
//  Created by Mac14 on 12/1/24.
//

// ContentView.swift

import SwiftUI

struct ContentView: View {
    @StateObject var navigationManager = NavigationManager()
    
    var body: some View {
        NavigationStack(path: $navigationManager.navigationPath) {
            HomePage(navigationManager: navigationManager)
                .navigationDestination(for: AnyPage.self) { page in
                    page
                }
        }
    }
}



#Preview {
    ContentView()
}
