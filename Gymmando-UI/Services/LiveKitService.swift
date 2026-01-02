import Foundation
import LiveKit
import AVFoundation
import Combine

@MainActor
class LiveKitService: ObservableObject {
    
    @Published var connected = false
    @Published var remoteAudioLevel: Float = 0 // Tracks AI's speaking volume
    
    private var room: Room?
    private var audioLevelTimer: Timer? // Timer for monitoring remote audio
    
    func connect(url: String, token: String) async {
        print("🔴 [LiveKit] STEP 1: Function entered")
        print("🔴 [LiveKit] URL: \(url)")
        print("🔴 [LiveKit] Token length: \(token.count)")
        print("🔴 [LiveKit] Current connected state: \(self.connected)")
        print("🔴 [LiveKit] Current room exists: \(self.room != nil)")
        
        print("🔴 [LiveKit] STEP 2: About to start connection")
        do {
            print("🔴 [LiveKit] STEP 3: Before audio session")
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.defaultToSpeaker, .allowBluetoothA2DP, .allowBluetooth]
            )
            // Enable background audio
            try session.setActive(true, options: [])
            print("✅ [LiveKit] Audio session active with background support")
            
            print("🔴 [LiveKit] STEP 4: Creating room")
            let newRoom = Room()
            self.room = newRoom
            print("✅ [LiveKit] Room created")
            
            print("🔴 [LiveKit] STEP 5: About to connect to LiveKit server...")
            try await newRoom.connect(url: url, token: token)
            print("✅ [LiveKit] Connected to room!")
            
            print("🔴 [LiveKit] STEP 6: Enabling microphone")
            try await newRoom.localParticipant.setMicrophone(enabled: true)
            print("✅ [LiveKit] Microphone enabled")
            
            self.connected = true
            self.startRemoteAudioMonitoring() // Start monitoring after connection
            print("✅ [LiveKit] Connection complete! connected = \(self.connected)")
            
        } catch {
            print("❌ [LiveKit] ERROR at some step: \(error)")
            print("❌ [LiveKit] Error type: \(type(of: error))")
            print("❌ [LiveKit] Error localized: \(error.localizedDescription)")
            self.connected = false
        }
    }
    
    func disconnect() async {
        print("🔵 [LiveKit] Disconnect called")
        print("🔵 [LiveKit] Room exists: \(self.room != nil)")
        
        guard let room = self.room else {
            print("⚠️ [LiveKit] No room to disconnect")
            return
        }
        
        print("🔵 [LiveKit] Disabling microphone...")
        try? await room.localParticipant.setMicrophone(enabled: false)
        
        print("🔵 [LiveKit] Disconnecting room...")
        await room.disconnect()
        
        self.connected = false
        self.room = nil
        self.stopRemoteAudioMonitoring() // Stop monitoring on disconnect
        print("✅ [LiveKit] Disconnected completely")
    }
    
    private func startRemoteAudioMonitoring() {
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRemoteAudioLevel()
            }
        }
    }
    
    private func stopRemoteAudioMonitoring() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        remoteAudioLevel = 0
    }
    
    private func updateRemoteAudioLevel() {
        guard let room = room else {
            remoteAudioLevel = 0
            return
        }
        
        // Check if any remote participant is speaking
        let isSpeaking = room.remoteParticipants.values.contains { $0.isSpeaking }
        
        if isSpeaking {
            // Smoothly increase with slight variation for natural feel
            let target: Float = 0.6 + Float.random(in: 0...0.3)
            remoteAudioLevel = remoteAudioLevel * 0.7 + target * 0.3
        } else {
            // Smoothly decrease
            remoteAudioLevel = remoteAudioLevel * 0.85
            if remoteAudioLevel < 0.05 {
                remoteAudioLevel = 0
            }
        }
    }
    
}
