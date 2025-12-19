import Foundation
import LiveKit
import AVFoundation
import Combine

@MainActor
class LiveKitService: ObservableObject {
    
    @Published var connected = false
    @Published var remoteAudioLevel: Float = 0
    private var room: Room?
    private var audioLevelTimer: Timer?
    private var targetAudioLevel: Float = 0
    
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
                options: [.defaultToSpeaker, .allowBluetoothA2DP]
            )
            try session.setActive(true)
            print("✅ [LiveKit] Audio session active")
            
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
            print("✅ [LiveKit] Connection complete! connected = \(self.connected)")
            
            // Start monitoring remote audio levels
            self.startRemoteAudioMonitoring()
            
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
        self.stopRemoteAudioMonitoring()
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
        guard let room = self.room else { return }
        
        // Get speaking state from remote participants
        var isSpeaking = false
        for participant in room.remoteParticipants.values {
            if participant.isSpeaking {
                isSpeaking = true
                break
            }
        }
        
        // Set target level based on speaking state
        targetAudioLevel = isSpeaking ? 0.8 : 0
        
        // Smooth transition towards target
        let smoothingUp: Float = 0.3    // Fast attack
        let smoothingDown: Float = 0.1  // Slower decay
        
        if targetAudioLevel > remoteAudioLevel {
            remoteAudioLevel += (targetAudioLevel - remoteAudioLevel) * smoothingUp
        } else {
            remoteAudioLevel += (targetAudioLevel - remoteAudioLevel) * smoothingDown
        }
        
        // Add slight variation when speaking for more natural look
        if isSpeaking {
            remoteAudioLevel += Float.random(in: -0.1...0.1)
            remoteAudioLevel = max(0.3, min(1.0, remoteAudioLevel))
        }
    }
}
