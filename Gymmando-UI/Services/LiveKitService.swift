import Foundation
import LiveKit
import AVFoundation

@MainActor
class LiveKitService: ObservableObject {
    
    @Published var connected = false
    private var room = Room()
    
    /// Connect to LiveKit and enable mic
    func connect(url: String, token: String) {
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                // 1️⃣ Setup audio session
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(
                    .playAndRecord,
                    mode: .voiceChat,
                    options: [.defaultToSpeaker, .allowBluetooth]
                )
                try session.setActive(true)
                
                // 2️⃣ Connect to LiveKit room (async)
                try await self.room.connect(url: url, token: token)
                
                // 3️⃣ Enable microphone track (async)
                try await self.room.localParticipant.setMicrophone(enabled: true)
                
                // 4️⃣ Update UI state
                await MainActor.run {
                    self.connected = true
                    print("✅ Connected and microphone enabled")
                }
                
            } catch {
                await MainActor.run {
                    self.connected = false
                    print("❌ LiveKit error:", error)
                }
            }
        }
    }
    
    /// Disconnect from LiveKit
    func disconnect() {
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                // Disable mic (async)
                try await self.room.localParticipant.setMicrophone(enabled: false)
                
                // Disconnect room (async if required)
                try await self.room.disconnect()
                
                // Update state
                await MainActor.run {
                    self.connected = false
                    print("🛑 Disconnected")
                }
                
                // Optional: deactivate audio session
                try? AVAudioSession.sharedInstance().setActive(false)
                
            } catch {
                print("⚠️ Disconnect error:", error)
            }
        }
    }
}
