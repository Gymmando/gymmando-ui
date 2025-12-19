//
//  Gymmando_UIApp.swift
//  Gymmando-UI
//
//  Created by Abdu Radi on 11/25/25.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct Gymmando_UIApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
