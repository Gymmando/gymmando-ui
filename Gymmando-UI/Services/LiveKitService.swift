import Foundation
import LiveKit
import AVFoundation

@MainActor
class LiveKitService: ObservableObject {
    
    @Published var connected = false
    private var room: Room?
    
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
        print("✅ [LiveKit] Disconnected completely")
    }
}
