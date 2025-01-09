//
//  NavTemplateApp.swift
//  NavTemplate
//
//  Created by Mac14 on 12/1/24.
//

import SwiftUI
import NavTemplateShared

@main
struct NavTemplateApp: App {
    @StateObject var navigationManager = NavigationManager()
    
    init() {
        // Initialize logger for main app
        Logger.initialize(target: "NavTemplate")
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationManager.navigationPath) {
                AnyPage(HomePage(navigationManager: navigationManager))
                    .navigationDestination(for: AnyPage.self) { page in
                        page
                    }
            }
        }
    }
}
