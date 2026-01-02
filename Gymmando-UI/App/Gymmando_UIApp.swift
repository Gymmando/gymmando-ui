//
//  Gymmando_UIApp.swift
//  Gymmando-UI
//
//  Created by Abdu Radi on 11/25/25.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn
import AVFoundation

@main
struct Gymmando_UIApp: App {
    init() {
        FirebaseApp.configure()
        // Configure audio session for background audio
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.defaultToSpeaker, .allowBluetoothA2DP, .allowBluetooth]
            )
            try session.setActive(true)
            print("✅ App: Audio session configured for background")
        } catch {
            print("❌ App: Failed to configure audio session: \(error)")
        }
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
