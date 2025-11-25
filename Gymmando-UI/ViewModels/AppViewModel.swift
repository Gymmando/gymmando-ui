import Foundation

@MainActor
class AppViewModel: ObservableObject {
    @Published var liveKit = LiveKitService()
    
    func connect() async {
        let url = "wss://gymbo-li7l0in9.livekit.cloud"
        
        do {
            // 1️⃣ Fetch the access token from your server
            guard let tokenURL = URL(string: "https://your-server.com/getToken") else { return }
            let (data, _) = try await URLSession.shared.data(from: tokenURL)
            
            // 2️⃣ Decode JSON
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let token = json?["token"] as? String else {
                print("Token not found in response")
                return
            }
            
            // 3️⃣ Connect to LiveKit with fetched token
            // ❌ Do NOT use await here because LiveKitService.connect() handles async internally
            liveKit.connect(url: url, token: token)
            
        } catch {
            print("Error fetching token or connecting:", error)
        }
    }
}
