import Foundation
import FirebaseAuth

@MainActor
class AppViewModel: ObservableObject {
    @Published var liveKit = LiveKitService()
    
    init() {
        print("🎬 AppViewModel: init() called")
    }
    
    func connect() async {
        print("🔴🔴🔴 CONNECT CALLED 🔴🔴🔴")
        
        // Get Firebase user ID
        print("🔍 Checking Firebase Auth state...")
        guard let currentUser = Auth.auth().currentUser else {
            print("⚠️ No authenticated user found - Auth.auth().currentUser is nil")
            print("⚠️ This means you need to sign in with email/password or Google Sign-In")
            return
        }
        
        let userID = currentUser.uid
        print("✅ Firebase User ID: \(userID)")
        print("✅ User Email: \(currentUser.email ?? "no email")")
        
        do {
            // Use fixed room for now
            let roomName = "gym-room"
            
            // Build URL with user_id as query parameter
            var components = URLComponents(string: "https://gymmando-api-cjpxcek7oa-uc.a.run.app/token")!
            components.queryItems = [
                URLQueryItem(name: "user_id", value: userID)
            ]
            
            guard let tokenURL = components.url else {
                print("❌ Invalid URL")
                return
            }
            
            print("🟦 Fetching token with user_id=\(userID)...")
            print("🟦 Full URL: \(tokenURL.absoluteString)")
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
