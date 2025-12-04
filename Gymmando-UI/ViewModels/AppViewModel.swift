import Foundation

@MainActor
class AppViewModel: ObservableObject {
    @Published var liveKit = LiveKitService()
    
    func connect() async {
        print("🔴🔴🔴 CONNECT CALLED 🔴🔴🔴")
        
        do {
            // Use fixed room for now
            let roomName = "gym-room"
            
            guard let tokenURL = URL(string: "https://gymmando-api-cjpxcek7oa-uc.a.run.app/token") else {
                print("❌ Invalid URL")
                return
            }
            
            print("🟦 Fetching token...")
            let (data, _) = try await URLSession.shared.data(from: tokenURL)
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let token = json?["token"] as? String else {
                print("❌ No token")
                return
            }
            
            print("✅ Token received")
            
            let url = "wss://gymbo-li7l0in9.livekit.cloud"
            await liveKit.connect(url: url, token: token)
            
        } catch {
            print("❌ Error:", error)
        }
    }
}
