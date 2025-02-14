//
//  EchoPlayApp.swift
//  EchoPlay
//
//  Created by Gabrielle Mccrae on 11/26/24.
//

import SwiftUI
import FirebaseCore

@main
struct EchoPlayApp: App {
    @State private var userManager: UserManager
    
    init() {
        FirebaseApp.configure()
        userManager = UserManager()
    }
    
    var body: some Scene {
        WindowGroup {
            if userManager.currentUser != nil {
                MainTabView()
                    .environment(userManager)
            } else {
                LoginView()
                    .environment(userManager)
            }
        }
    }
}
