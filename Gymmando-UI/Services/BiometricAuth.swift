import LocalAuthentication

class BiometricAuth {
    static let shared = BiometricAuth()
    
    func authenticate(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric auth is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Log in to Gymmando"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    completion(success, authError)
                }
            }
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            // Biometric not available, try passcode
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Log in to Gymmando") { success, authError in
                DispatchQueue.main.async {
                    completion(success, authError)
                }
            }
        } else {
            // Neither biometric nor passcode available
            DispatchQueue.main.async {
                completion(false, error)
            }
        }
    }
}
